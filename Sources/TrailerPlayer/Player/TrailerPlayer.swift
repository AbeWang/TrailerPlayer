//
//  TrailerPlayer.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/13.
//

import AVFoundation

public class TrailerPlayer: AVPlayer {
 
    private let fairplayQueue = DispatchQueue(label: "trailerPlayer.fairplay.queue")
    
    private var debugInfo = TrailerPlayerDebugInfo()
    
    private var periodicTimeObserver: Any?
    private var periodicTimeObserverForDebug: Any?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    
    private var previousTimeControlStatus: TimeControlStatus = .paused
    
    public weak var handler: TrailerPlayerView?
    
    public private(set) var isDRMContent = false
    
    var debugEnabled = false
    
    var playbackReadyCallback: (() -> Void)?
    var isBufferingCallback: ((Bool) -> Void)?
    var debugInfoCallback: ((TrailerPlayerDebugInfo) -> Void)?
    
    public var duration: TimeInterval {
        guard let time = currentItem?.duration else { return 0.0 }
        return CMTimeGetSeconds(time)
    }
    
    public var playbackStatus: TrailerPlayerPlaybackStatus {
        switch timeControlStatus {
        case .playing: return .playing
        case .paused: return .pause
        case .waitingToPlayAtSpecifiedRate: return .waitingToPlay
        default: return .unknown
        }
    }
    
    deinit {
        reset()
    }
    
    public required init(playerItem item: AVPlayerItem, isDRMContent drmContent: Bool = false) {
        super.init()
        
        replaceCurrentItem(with: item)
        isDRMContent = drmContent
        
        setup()
    }
}

public extension TrailerPlayer {
    
    func replay() {
        seek(to: 0.0)
        play()
    }
    
    func seek(to time: TimeInterval) {
        seek(to: CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }
    
    func toggleMute() { isMuted = !isMuted }
    
    override func replaceCurrentItem(with item: AVPlayerItem?) {
        if currentItem != nil {
            reset()
        }
        super.replaceCurrentItem(with: item)
    }
}

private extension TrailerPlayer {
    
    func setup() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)

        if let asset = currentItem?.asset as? AVURLAsset, isDRMContent {
            asset.resourceLoader.setDelegate(self, queue: fairplayQueue)
        }
        
        periodicTimeObserver = addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] _ in
            guard let self = self, self.timeControlStatus == .playing else { return }
            self.handler?.playbackDelegate?.trailerPlayer(self, didUpdatePlaybackTime: CMTimeGetSeconds(self.currentTime()))
        }
        
        periodicTimeObserverForDebug = addPeriodicTimeObserver(forInterval:CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] _ in
            guard
                let self = self, self.debugEnabled,
                let callback = self.debugInfoCallback,
                let item = self.currentItem
            else { return }
            
            self.debugInfo.trailerUrl = (item.asset as? AVURLAsset)?.url
            self.debugInfo.playbackItemURI = item.accessLog()?.events.last?.uri
            self.debugInfo.bitrate = item.accessLog()?.events.last?.indicatedBitrate
            self.debugInfo.frameRate = item.tracks.first?.currentVideoFrameRate
            self.debugInfo.resolution = item.tracks.first?.assetTrack?.naturalSize
            callback(self.debugInfo)
        }
        
        statusObserver = currentItem?.observe(\.status, options: [.new]) { [weak self] _, _ in
            guard let self = self, let item = self.currentItem else { return }
            switch item.status {
            case .readyToPlay:
                self.handler?.playbackDelegate?.trailerPlayerPlaybackReady(self)
                self.playbackReadyCallback?()
            case .failed:
                self.handler?.playbackDelegate?.trailerPlayer(self, playbackDidFailed: .loadFailed)
            default:
                self.handler?.playbackDelegate?.trailerPlayer(self, playbackDidFailed: .unknown)
            }
        }
        
        timeControlStatusObserver = observe(\.timeControlStatus, options: [.old, .new]) { [weak self] _, _ in
            guard let self = self else { return }
            
            // newValue and oldValue always nil when observing .timeControlStatus
            // https://bugs.swift.org/browse/SR-5872
            let newValue = self.timeControlStatus
            let oldValue = self.previousTimeControlStatus
            self.previousTimeControlStatus = newValue

            switch (oldValue, newValue) {
            case (.waitingToPlayAtSpecifiedRate, _) where newValue != .waitingToPlayAtSpecifiedRate:
                self.isBufferingCallback?(false)
            case (_, .waitingToPlayAtSpecifiedRate) where oldValue != .waitingToPlayAtSpecifiedRate:
                self.isBufferingCallback?(true)
            default:
                break
            }
            
            self.handler?.playbackDelegate?.trailerPlayer(self, didChangePlaybackStatus: self.playbackStatus)
        }
    }
    
    func reset() {
        if let observer = periodicTimeObserver {
            removeTimeObserver(observer)
            periodicTimeObserver = nil
        }
        
        if let observer = periodicTimeObserverForDebug {
            removeTimeObserver(observer)
            periodicTimeObserverForDebug = nil
        }
        
        statusObserver?.invalidate()
        statusObserver = nil
        
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
        
        playbackReadyCallback = nil
        isBufferingCallback = nil
        debugInfoCallback = nil
    }
}

extension TrailerPlayer: AVAssetResourceLoaderDelegate {
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard
            let url = loadingRequest.request.url,
            let scheme = url.scheme,
            scheme == "skd"
        else {
            loadingRequest.finishLoading(with: TrailerPlayerDRMError.noRequestUrl)
            return false
        }
        
        guard
            let certificateUrl = handler?.DRMDelegate?.certUrl(for: self),
            let certificateData = try? Data(contentsOf: certificateUrl)
        else {
            loadingRequest.finishLoading(with: TrailerPlayerDRMError.noCertificateData)
            return false
        }
        
        let contentId = handler?.DRMDelegate?.contentId(for: self) ?? url.host
        guard
            let contentIdData = contentId?.data(using: .utf8),
            let SPCData = try? loadingRequest.streamingContentKeyRequestData(forApp: certificateData, contentIdentifier: contentIdData, options: nil)
        else {
            loadingRequest.finishLoading(with: TrailerPlayerDRMError.noSPCData)
            return false
        }
        
        guard let ckcUrl = handler?.DRMDelegate?.ckcUrl(for: self) else {
            loadingRequest.finishLoading(with: TrailerPlayerDRMError.noCKCUrl)
            return false
        }
        
        var ckcRequest = URLRequest(url: ckcUrl)
        ckcRequest.httpMethod = "POST"
        ckcRequest.httpBody = SPCData
        if let fields = handler?.DRMDelegate?.ckcRequestHeaderFields(for: self) {
            fields.forEach { headerField, value in
                ckcRequest.addValue(value, forHTTPHeaderField: headerField)
            }
        }
        
        URLSession.shared.dataTask(with: ckcRequest) { data, response, error in
            guard let ckcData = data else {
                loadingRequest.finishLoading(with: TrailerPlayerDRMError.noCKCData)
                return
            }
            loadingRequest.dataRequest?.respond(with: ckcData)
            loadingRequest.finishLoading()
        }
        .resume()
        
        return true
    }
}
