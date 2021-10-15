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
    
    private var player: TrailerPlayer?
    private var playerLayer: AVPlayerLayer?
    private var currentPlayingItem: TrailerPlayerItem?
    private var shouldResumePlay = false
    
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
    
    func toggleMute() { player?.toggleMute() }
    
    func play() { player?.play() }
    
    func pause() { player?.pause() }
    
    func replay() {
        player?.replay()
        playerView.isHidden = false
        replayPanel?.isHidden = true
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: time)
        playerView.isHidden = false
        replayPanel?.isHidden = true
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
        
        let playerItem = AVPlayerItem(url: url)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidEndPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        player = TrailerPlayer(playerItem: playerItem, isDRMContent: item.isDRMContent)
        player?.handler = self
        player?.isMuted = item.mute
        player?.playbackReadyCallback = { [weak self] in
            guard let self = self else { return }
            self.playerView.isHidden = false
        }
        player?.isBufferingCallback = { [weak self] buffering in
            guard let self = self else { return }
            if buffering {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
        }
        
        playerLayer = AVPlayerLayer(player: player)
        playerView.layer.addSublayer(playerLayer!)
        
        setPictureInPicture(enabled: pipEnabled)
        
        if item.autoPlay { play() }
    }
    
    func reset() {
        NotificationCenter.default.removeObserver(self)
        
        currentPlayingItem = nil
        pipController = nil
        
        thumbnailView.image = nil
        
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
            pipController = nil
        } else if let layer = playerLayer, pipController == nil {
            pipController = AVPictureInPictureController(playerLayer: layer)
            pipController?.delegate = self
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
}

extension TrailerPlayerView: AVPictureInPictureControllerDelegate {
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}
