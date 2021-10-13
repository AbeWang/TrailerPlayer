//
//  TrailerPlayerView.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/1.
//

import AVFoundation
import UIKit
import AVKit

public class TrailerPlayerView: UIView {
    
    public weak var playbackDelegate: TrailerPlayerViewPlaybackDelegate?
    public weak var DRMDelegate: TrailerPlayerViewDRMDelegate?
    
    public var isMuted: Bool {
        player?.isMuted ?? true
    }
    
    public var canUseFullscreen: Bool {
        currentPlayingItem?.videoUrl != nil
    }
    
    public var enablePictureInPicture: Bool {
        get { pipEnabled }
        set { setPictureInPicture(enabled: newValue) }
    }
    
    public var duration: TimeInterval {
        guard let time = player?.currentItem?.duration else { return 0.0 }
        return CMTimeGetSeconds(time)
    }
    
    public var status: TrailerPlayerPlaybackStatus {
        guard let status = player?.timeControlStatus else { return .unknown }
        switch status {
        case .playing: return .playing
        case .paused: return .pause
        case .waitingToPlayAtSpecifiedRate: return .waitingToPlay
        default: return .unknown
        }
    }
    
    @AutoLayout
    public private(set) var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    @AutoLayout
    private var thumbnailView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.backgroundColor = .black
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    @AutoLayout
    private var playerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.isHidden = true
        return view
    }()
    
    @AutoLayout
    private var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.style = .whiteLarge
        return view
    }()
    
    private let fairplayQueue = DispatchQueue(label: "abewang.fairplay.queue")
    
    private var player: TrailerPlayer?
    private var playerLayer: AVPlayerLayer?
    private var pictureInPictureController: AVPictureInPictureController?
    private var currentPlayingItem: TrailerPlayerItem?
    private var shouldResumePlay = false
    private var pipEnabled = false
    private var periodicTimeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var previousTimeControlStatus: AVPlayer.TimeControlStatus?
    
    private weak var controlPanel: UIView?
    private weak var replayPanel: UIView?
    private var isControlPanelShowing = false
    private var controlPanelAutoFadeOutWorkItem: DispatchWorkItem?
    private var controlPanelAutoFadeOutDuration: TimeInterval = 3.0
    private var tapGesture: UITapGestureRecognizer?
    
    deinit {
        reset()
    }
    
    public init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        playerLayer?.frame = CGRect(x: 0.0, y: 0.0, width: containerView.frame.width, height: containerView.frame.height)
    }
}

public extension TrailerPlayerView {
    
    func set(item: TrailerPlayerItem) {
        loadingIndicator.startAnimating()
        
        reset()
        
        currentPlayingItem = item
        
        if let url = item.thumbnailUrl {
            fetchThumbnailImage(url)
        }
        if item.videoUrl != nil {
            setupPlayer(item)
        }
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func replay() {
        seek(to: 0.0)
        play()
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC)))
        playerView.isHidden = false
        replayPanel?.isHidden = true
    }
    
    func toggleMute() {
        guard let player = player else { return }
        player.isMuted = !player.isMuted
    }
    
    func fullscreen(enabled: Bool, rotateTo orientation: UIInterfaceOrientation? = nil) {
        guard let window = UIApplication.shared.keyWindow, canUseFullscreen else { return }
        
        containerView.removeFromSuperview()
        layout(view: containerView, into: enabled ? window: self)
        
        if let orientation = orientation {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }
    
    func addControlPanel(_ view: UIView, autoFadeOutDuration duration: TimeInterval = 3.0) {
        removeControlPanel()
        
        controlPanel = view
        controlPanelAutoFadeOutDuration = duration
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGestureTapped))
        playerView.addGestureRecognizer(tapGesture!)
        
        layout(view: view, into: playerView, animated: false)
        view.alpha = isControlPanelShowing ? 1.0: 0.0
        view.layer.zPosition = 999
    }
    
    func removeControlPanel() {
        controlPanel?.removeFromSuperview()
        controlPanel = nil
        
        guard let gesture = tapGesture else { return }
        playerView.removeGestureRecognizer(gesture)
        tapGesture = nil
    }
    
    func addReplayPanel(_ view: UIView) {
        removeReplayPanel()
        
        replayPanel = view
        
        layout(view: view, into: containerView, animated: false)
        view.isHidden = true
    }
    
    func removeReplayPanel() {
        replayPanel?.removeFromSuperview()
        replayPanel = nil
    }
    
    func autoFadeOutControlPanelWithAnimation() {
        guard controlPanel != nil else { return }
        
        cancelAutoFadeOutAnimation()

        controlPanelAutoFadeOutWorkItem = DispatchWorkItem { [weak self] in
            self?.controlPanelAnimation(isShow: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + controlPanelAutoFadeOutDuration, execute: controlPanelAutoFadeOutWorkItem!)
    }
    
    func cancelAutoFadeOutAnimation() {
        controlPanelAutoFadeOutWorkItem?.cancel()
    }
}

private extension TrailerPlayerView {
    
    func setup() {
        backgroundColor = .black
        
        layout(view: containerView, into: self, animated: false)
        layout(view: thumbnailView, into: containerView, animated: false)
        layout(view: playerView, into: containerView, animated: false)
        
        containerView.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor).isActive = true
    }
    
    func fetchThumbnailImage(_ url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let data = data, error == nil else { return }
                
                if self.currentPlayingItem?.videoUrl == nil {
                    self.loadingIndicator.stopAnimating()
                }
                
                UIView.transition(with: self.thumbnailView, duration: 0.25, options: .transitionCrossDissolve) {
                    self.thumbnailView.image = UIImage(data: data)
                } completion: {_ in }
            }
        }
        .resume()
    }
    
    func setupPlayer(_ item: TrailerPlayerItem) {
        guard let url = item.videoUrl else { return }
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        
        let playerItem = AVPlayerItem(url: url)
        player = TrailerPlayer(playerItem: playerItem)
        
        if let asset = playerItem.asset as? AVURLAsset, item.isDRMContent {
            asset.resourceLoader.setDelegate(self, queue: fairplayQueue)
        }
        
        previousTimeControlStatus = player?.timeControlStatus
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidEndPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] _, _ in
            guard let self = self, let item = self.player?.currentItem else { return }
            switch item.status {
            case .readyToPlay:
                self.playbackDelegate?.trailerPlayerViewReadyToPlay(self)
                self.playerView.isHidden = false
            case .failed:
                self.playbackDelegate?.trailerPlayerView(self, playbackDidFailed: .loadFailed)
            default:
                self.playbackDelegate?.trailerPlayerView(self, playbackDidFailed: .unknown)
            }
        }
        
        periodicTimeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] _ in
            guard
                let self = self,
                let player = self.player,
                player.timeControlStatus == .playing
            else { return }
            
            self.playbackDelegate?.trailerPlayerView(self, didUpdatePlaybackTime: CMTimeGetSeconds(player.currentTime()))
        }
        
        timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.old, .new]) { [weak self] player, _ in
            guard let self = self else { return }
            
            // newValue and oldValue always nil when observing .timeControlStatus
            // https://bugs.swift.org/browse/SR-5872
            let newValue = player.timeControlStatus
            let oldValue = self.previousTimeControlStatus
            self.previousTimeControlStatus = newValue

            switch (oldValue, newValue) {
            case (.waitingToPlayAtSpecifiedRate, _) where newValue != .waitingToPlayAtSpecifiedRate:
                self.loadingIndicator.stopAnimating()
            case (_, .waitingToPlayAtSpecifiedRate) where oldValue != .waitingToPlayAtSpecifiedRate:
                self.loadingIndicator.startAnimating()
            default:
                break
            }
            
            self.playbackDelegate?.trailerPlayerView(self, didChangePlaybackStatus: self.status)
        }
        
        playerLayer = AVPlayerLayer(player: player)
        playerView.layer.addSublayer(playerLayer!)
        
        setPictureInPicture(enabled: pipEnabled)
        
        player?.isMuted = item.mute
        if item.autoPlay {
            player?.play()
        }
    }
    
    func reset() {
        NotificationCenter.default.removeObserver(self)
        
        currentPlayingItem = nil
        previousTimeControlStatus = nil
        
        thumbnailView.image = nil
        
        if let observer = periodicTimeObserver {
            player?.removeTimeObserver(observer)
            periodicTimeObserver = nil
        }
        
        statusObserver?.invalidate()
        statusObserver = nil
        
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
        
        pictureInPictureController = nil
        
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    func layout(view: UIView, into: UIView, animated: Bool = true) {
        guard view.superview == nil else { return }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        
        into.addSubview(view)
        
        let duration = animated ? 0.25: 0.0
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseOut) {
            view.topAnchor.constraint(equalTo: into.topAnchor).isActive = true
            view.leftAnchor.constraint(equalTo: into.leftAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: into.rightAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: into.bottomAnchor).isActive = true
            view.alpha = 1
            view.layoutIfNeeded()
        } completion: { _ in }
    }
    
    func setPictureInPicture(enabled: Bool) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        
        pipEnabled = enabled
        
        if !enabled {
            pictureInPictureController = nil
        } else if let layer = playerLayer, pictureInPictureController == nil {
            pictureInPictureController = AVPictureInPictureController(playerLayer: layer)
            pictureInPictureController?.delegate = self
        }
    }
    
    func controlPanelAnimation(isShow: Bool) {
        guard let panel = controlPanel else { return }
        
        isControlPanelShowing = isShow
        
        UIView.animate(withDuration: 0.25) {
            panel.alpha = isShow ? 1.0: 0.0
            self.layoutIfNeeded()
        } completion: { _ in
            if isShow {
                self.autoFadeOutControlPanelWithAnimation()
            }
        }
    }
    
    @objc func playerDidEndPlaying() {
        guard let item = currentPlayingItem else { return }
        
        if item.autoReplay {
            replay()
        } else {
            playerView.isHidden = true
            replayPanel?.isHidden = false
            
            playbackDelegate?.trailerPlayerViewDidEndPlaying(self)
            if pipEnabled {
                // Reset PIP
                pictureInPictureController = nil
                setPictureInPicture(enabled: true)
            }
        }
    }
    
    @objc func appWillEnterForeground() {
        if shouldResumePlay {
            shouldResumePlay = false
            play()
        }
    }
    
    @objc func appDidEnterBackground() {
        guard status == .playing || status == .waitingToPlay else { return }
        shouldResumePlay = true
    }
    
    @objc func onTapGestureTapped() {
        guard controlPanel != nil else { return }
        controlPanelAnimation(isShow: !isControlPanelShowing)
    }
}

extension TrailerPlayerView: AVAssetResourceLoaderDelegate {
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else {
            loadingRequest.finishLoading(with: TrailerPlayerDRMError.noRequestUrl)
            return false
        }
        
        print("[TrailerPlayer] resource loading: \(url)")
        
        guard
            let certificateUrl = DRMDelegate?.certificateURL(for: self),
            let certificateData = try? Data(contentsOf: certificateUrl)
        else {
            loadingRequest.finishLoading(with: TrailerPlayerDRMError.noCertificateData)
            return false
        }
        
        let contentId = DRMDelegate?.contentID(for: self) ?? url.host
        guard
            let contentIdData = contentId?.data(using: .utf8),
            let SPCData = try? loadingRequest.streamingContentKeyRequestData(forApp: certificateData, contentIdentifier: contentIdData, options: nil)
        else {
            loadingRequest.finishLoading(with: TrailerPlayerDRMError.noSPCData)
            return false
        }
        
        guard let ckcUrl = DRMDelegate?.contentKeyContextURL(for: self) else {
            loadingRequest.finishLoading(with: TrailerPlayerDRMError.noCKCUrl)
            return false
        }
        
        var ckcRequest = URLRequest(url: ckcUrl)
        ckcRequest.httpMethod = "POST"
        ckcRequest.httpBody = SPCData
        if let fields = DRMDelegate?.ckcRequestHeaderFields(for: self) {
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

extension TrailerPlayerView: AVPictureInPictureControllerDelegate {
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}
