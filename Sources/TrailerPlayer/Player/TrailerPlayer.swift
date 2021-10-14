//
//  TrailerPlayer.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/13.
//

import Foundation
import AVFoundation

public class TrailerPlayer: AVPlayer {
 
    private let fairplayQueue = DispatchQueue(label: "trailerPlayer.fairplay.queue")
    
    public weak var handler: TrailerPlayerView?
    
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
        super.init(playerItem: item)
        
        if let asset = item.asset as? AVURLAsset, drmContent {
            asset.resourceLoader.setDelegate(self, queue: fairplayQueue)
        }
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    }
    
    override public init() {
        super.init()
    }
}

public extension TrailerPlayer {
    
    func replay() {
        seek(to: 0.0)
        play()
    }
    
    func seek(to time: TimeInterval) {
        seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC)))
    }
    
    func toggleMute() {
        isMuted = !isMuted
    }
}

private extension TrailerPlayer {
    
    func reset() {
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
