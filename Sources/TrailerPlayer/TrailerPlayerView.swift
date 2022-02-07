//
//  TrailerPlayerView.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/1.
//

import AVKit

public class TrailerPlayerView: UIView {
    
    public weak var playbackDelegate: TrailerPlayerPlaybackDelegate?
    public weak var DRMDelegate: TrailerPlayerDRMDelegate?
    
    public var isMuted: Bool { player?.isMuted ?? true }
    
    public var canUseFullscreen: Bool { player != nil }
    
    public var duration: TimeInterval { player?.duration ?? 0.0 }
    
    public var status: TrailerPlayerPlaybackStatus { player?.playbackStatus ?? .unknown }
    
    public var enablePictureInPicture: Bool {
        get { pipEnabled }
        set { setPictureInPicture(enabled: newValue) }
    }
    
    public var enableDebugView: Bool {
        get { debugViewEnabled }
        set { setDebugView(enabled: newValue) }
    }
    
    public var manualPlayButton: UIButton? {
        didSet {
            manualPlayButton?.translatesAutoresizingMaskIntoConstraints = false
            manualPlayButton?.addTarget(self, action: #selector(didTapManualPlay), for: .touchUpInside)
        }
    }
    
    @AutoLayout
    public private(set) var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    @AutoLayout
    public private(set) var thumbnailView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.backgroundColor = .black
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    @AutoLayout
    public private(set) var playerView: UIView = {
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
    
    @AutoLayout
    private var debugInfoLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14.0)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return label
    }()
    
    private var player: TrailerPlayer?
    private var playerLayer: AVPlayerLayer?
    private var currentPlayingItem: TrailerPlayerItem?
    private var shouldResumePlay = false
    private var trailerFinished = false
    private var debugViewEnabled = false
    
    private var pipController: AVPictureInPictureController?
    private var pipEnabled = false
    
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
        playerLayer?.frame = containerView.frame
    }
}

public extension TrailerPlayerView {
    
    func set(item: TrailerPlayerItem) {
        reset()
        
        currentPlayingItem = item
        
        setupThumbnail()
        setupPlayer()
    }
    
    func toggleMute() { player?.toggleMute() }
    
    func play() {
        playerView.isHidden = false
        player?.play()
    }
    
    func pause() { player?.pause() }
    
    func stop() {
        let item = TrailerPlayerItem(thumbnailUrl: currentPlayingItem?.thumbnailUrl,
                                     thumbnailImage: currentPlayingItem?.thumbnailImage)
        
        reset()
        currentPlayingItem = item
        setupThumbnail()
    }
    
    func replay() {
        switchToPlayerView()
        player?.replay()
    }
    
    func seek(to time: TimeInterval) {
        switchToPlayerView()
        player?.seek(to: time)
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
    
    func cancelAutoFadeOutAnimation() { controlPanelAutoFadeOutWorkItem?.cancel() }
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
        
        containerView.addSubview(debugInfoLabel)
        if #available(iOS 11.0, *) {
            debugInfoLabel.leftAnchor.constraint(equalTo: self.containerView.safeAreaLayoutGuide.leftAnchor).isActive = true
            debugInfoLabel.rightAnchor.constraint(equalTo: self.containerView.safeAreaLayoutGuide.rightAnchor).isActive = true
            debugInfoLabel.topAnchor.constraint(equalTo: self.containerView.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            debugInfoLabel.leftAnchor.constraint(equalTo: self.containerView.leftAnchor).isActive = true
            debugInfoLabel.rightAnchor.constraint(equalTo: self.containerView.rightAnchor).isActive = true
            debugInfoLabel.topAnchor.constraint(equalTo: self.containerView.topAnchor).isActive = true
        }
    }
    
    func fetchThumbnailImage(_ url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let data = data, error == nil else { return }
                UIView.transition(with: self.thumbnailView, duration: 0.25, options: .transitionCrossDissolve) {
                    self.thumbnailView.image = UIImage(data: data)
                } completion: {_ in }
            }
        }
        .resume()
    }
    
    func setupThumbnail() {
        guard let item = currentPlayingItem else { return }
        
        if let image = item.thumbnailImage {
            UIView.transition(with: thumbnailView, duration: 0.25, options: .transitionCrossDissolve) {
                self.thumbnailView.image = image
            } completion: {_ in }
        }
        if let url = item.thumbnailUrl {
            fetchThumbnailImage(url)
        }
    }
    
    func setupPlayer() {
        guard let item = currentPlayingItem, let url = item.videoUrl else { return }
        
        loadingIndicator.startAnimating()
        
        let playerItem = AVPlayerItem(url: url)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidEndPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        player = TrailerPlayer(playerItem: playerItem, isDRMContent: item.isDRMContent)
        player?.handler = self
        player?.isMuted = item.mute
        player?.playbackReadyCallback = { [weak self] in
            guard let self = self, !self.trailerFinished else { return }
            if item.autoPlay {
                self.play()
            } else {
                self.loadingIndicator.stopAnimating()
                
                guard let playButton = self.manualPlayButton else { return }
                self.containerView.addSubview(playButton)
                playButton.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor).isActive = true
                playButton.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor).isActive = true
            }
        }
        player?.isBufferingCallback = { [weak self] buffering in
            guard let self = self else { return }
            if buffering {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
        }
        player?.debugInfoCallback = { [weak self] debugInfo in
            guard let self = self else { return }
            if let bitrate = debugInfo.bitrate {
                self.debugInfoLabel.text = "\((Int)(bitrate / 1000)) Kbps\n"
            }
            if let resolution = debugInfo.resolution {
                self.debugInfoLabel.text?.append("\((Int)(resolution.width)) x \((Int)(resolution.height))\n")
            }
            if let frameRate = debugInfo.frameRate {
                self.debugInfoLabel.text?.append("\((Int)(frameRate)) fps\n")
            }
            if let url = debugInfo.trailerUrl {
                self.debugInfoLabel.text?.append("[Master] \(url.absoluteString)\n")
            }
            if let url = debugInfo.playbackItemURI {
                self.debugInfoLabel.text?.append("[Playback] \(url)")
            }
        }
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = containerView.frame
        playerView.layer.addSublayer(playerLayer!)
        
        setPictureInPicture(enabled: pipEnabled)
        setDebugView(enabled: debugViewEnabled)
    }
    
    func reset() {
        NotificationCenter.default.removeObserver(self)
        
        trailerFinished = false
        currentPlayingItem = nil
        pipController = nil
        
        thumbnailView.image = nil
        
        playerView.isHidden = true
        debugInfoLabel.isHidden = true
        
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
    
    func switchToPlayerView() {
        trailerFinished = false
        playerView.isHidden = false
        replayPanel?.isHidden = true
        setDebugView(enabled: debugViewEnabled)
    }
    
    func setPictureInPicture(enabled: Bool) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        
        pipEnabled = enabled
        
        if !enabled {
            pipController = nil
        } else if let layer = playerLayer, pipController == nil {
            pipController = AVPictureInPictureController(playerLayer: layer)
            pipController?.delegate = self
        }
    }
    
    func setDebugView(enabled: Bool) {
        debugViewEnabled = enabled
        debugInfoLabel.isHidden = !enabled
        
        if let player = player {
            player.debugEnabled = enabled
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
            trailerFinished = true
            playerView.isHidden = true
            replayPanel?.isHidden = false
            debugInfoLabel.isHidden = true
            
            if pipEnabled {
                pipController = nil
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
    
    @objc func didTapManualPlay() {
        manualPlayButton?.removeFromSuperview()
        play()
    }
}

extension TrailerPlayerView: AVPictureInPictureControllerDelegate {
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}
