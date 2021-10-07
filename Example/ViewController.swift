//
//  ViewController.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/9/28.
//

import UIKit

class ViewController: UIViewController {

    @AutoLayout
    private var playerView: TrailerPlayerView = {
        let view = TrailerPlayerView()
        view.enablePictureInPicture = true
        return view
    }()
    
    @AutoLayout
    private var controlPanel: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.5)
        return view
    }()
    
    @AutoLayout
    private var replayPanel: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = .black.withAlphaComponent(0.5)
        return view
    }()
    
    @AutoLayout
    private var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.isSelected = true
        button.setImage(UIImage(named: "audio")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "no-audio")?.withRenderingMode(.alwaysTemplate), for: .selected)
        return button
    }()
    
    @AutoLayout
    private var playPauseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.isSelected = false
        button.setImage(UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "play")?.withRenderingMode(.alwaysTemplate), for: .selected)
        return button
    }()
    
    @AutoLayout
    private var fullscreenButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.setImage(UIImage(named: "fullscreen")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "normal-screen")?.withRenderingMode(.alwaysTemplate), for: .selected)
        return button
    }()
    
    @AutoLayout
    private var countDownLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    @AutoLayout
    private var progressView: UISlider = {
        let view = UISlider()
        view.isContinuous = false
        view.thumbTintColor = .red
        view.tintColor = .red
        view.value = 0.0
        view.minimumValue = 0.0
        return view
    }()
    
    @AutoLayout
    private var replayButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.setImage(UIImage(named: "replay")?.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        let item = TrailerPlayerItem(
            url: URL(string: "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
            thumbnailUrl: URL(string: "https://upload.cc/i1/2021/10/04/qGNK3M.png"))
        playerView.delegate = self
        playerView.set(item: item)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let enableFullscreen = UIDevice.current.orientation.isLandscape
        fullscreenButton.isSelected = enableFullscreen
        playerView.fullscreen(enabled: enableFullscreen)
    }
}

private extension ViewController {
    
    func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(playerView)
        playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        playerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 0.65).isActive = true
        
        // Control Panel
        
        controlPanel.addSubview(playPauseButton)
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        playPauseButton.centerXAnchor.constraint(equalTo: controlPanel.centerXAnchor).isActive = true
        playPauseButton.centerYAnchor.constraint(equalTo: controlPanel.centerYAnchor).isActive = true
        playPauseButton.widthAnchor.constraint(equalToConstant: 60.0).isActive = true
        playPauseButton.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        
        controlPanel.addSubview(fullscreenButton)
        fullscreenButton.addTarget(self, action: #selector(didTapFullscreen), for: .touchUpInside)
        fullscreenButton.bottomAnchor.constraint(equalTo: controlPanel.safeAreaLayoutGuide.bottomAnchor).isActive = true
        fullscreenButton.rightAnchor.constraint(equalTo: controlPanel.safeAreaLayoutGuide.rightAnchor, constant: -10.0).isActive = true
        fullscreenButton.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        fullscreenButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        controlPanel.addSubview(muteButton)
        muteButton.addTarget(self, action: #selector(didTapMute), for: .touchUpInside)
        muteButton.rightAnchor.constraint(equalTo: controlPanel.safeAreaLayoutGuide.rightAnchor, constant: -10.0).isActive = true
        muteButton.bottomAnchor.constraint(equalTo: fullscreenButton.topAnchor).isActive = true
        muteButton.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        muteButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        controlPanel.addSubview(countDownLabel)
        countDownLabel.rightAnchor.constraint(equalTo: fullscreenButton.leftAnchor).isActive = true
        countDownLabel.bottomAnchor.constraint(equalTo: controlPanel.safeAreaLayoutGuide.bottomAnchor).isActive = true
        countDownLabel.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        countDownLabel.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        controlPanel.addSubview(progressView)
        progressView.addTarget(self, action: #selector(didChangePlaybackTime), for: .valueChanged)
        progressView.addTarget(self, action: #selector(didTouchDownProgressSlider), for: .touchDown)
        progressView.leftAnchor.constraint(equalTo: controlPanel.safeAreaLayoutGuide.leftAnchor, constant: 10.0).isActive = true
        progressView.rightAnchor.constraint(equalTo: countDownLabel.leftAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: controlPanel.safeAreaLayoutGuide.bottomAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        playerView.addControlPanel(controlPanel)
        
        // Replay Panel
        
        playerView.containerView.addSubview(replayPanel)
        replayPanel.widthAnchor.constraint(equalTo: playerView.containerView.widthAnchor).isActive = true
        replayPanel.heightAnchor.constraint(equalTo: playerView.containerView.heightAnchor).isActive = true
        
        replayPanel.addSubview(replayButton)
        replayButton.addTarget(self, action: #selector(didTapReplay), for: .touchUpInside)
        replayButton.centerXAnchor.constraint(equalTo: playerView.containerView.centerXAnchor).isActive = true
        replayButton.centerYAnchor.constraint(equalTo: playerView.containerView.centerYAnchor).isActive = true
        replayButton.widthAnchor.constraint(equalToConstant: 60.0).isActive = true
        replayButton.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
    }
    
    @objc func didTapMute() {
        muteButton.isSelected = !muteButton.isSelected
        playerView.toggleMute()
        playerView.autoFadeOutControlPanelWithAnimation()
    }
    
    @objc func didTapPlayPause() {
        if playerView.status == .playing {
            playerView.pause()
        } else {
            playerView.play()
        }
        playerView.autoFadeOutControlPanelWithAnimation()
    }
    
    @objc func didTapFullscreen() {
        fullscreenButton.isSelected = !fullscreenButton.isSelected
        playerView.fullscreen(enabled: fullscreenButton.isSelected,
                              rotateTo: fullscreenButton.isSelected ? .landscapeRight: .portrait)
        playerView.autoFadeOutControlPanelWithAnimation()
    }
    
    @objc func didChangePlaybackTime() {
        playerView.seek(to: TimeInterval(progressView.value))
        playerView.play()
        playerView.autoFadeOutControlPanelWithAnimation()
    }
    
    @objc func didTouchDownProgressSlider() {
        playerView.pause()
        playerView.cancelAutoFadeOutAnimation()
    }
    
    @objc func didTapReplay() {
        replayPanel.isHidden = true
        playerView.replay()
    }
}

extension ViewController: TrailerPlayerViewDelegate {
    
    func trailerPlayerViewDidEndPlaying(_ view: TrailerPlayerView) {
        replayPanel.isHidden = false
    }
    
    func trailerPlayerView(_ view: TrailerPlayerView, didUpdatePlaybackTime time: TimeInterval) {
        countDownLabel.text = "\(Int(playerView.duration - time))"
        progressView.value = Float(time)
        progressView.maximumValue = Float(playerView.duration)
    }
    
    func trailerPlayerView(_ view: TrailerPlayerView, didChangeStatus status: TrailerPlayerView.Status) {
        switch status {
        case .playing, .pause:
            playPauseButton.isHidden = false
            playPauseButton.isSelected = (status == .pause)
        case .waitingToPlay:
            playPauseButton.isHidden = true
        default:
            break
        }
    }
}
