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
    private var controlPanel: ControlPanel = {
        let view = ControlPanel()
        return view
    }()
    
    @AutoLayout
    private var replayPanel: ReplayPanel = {
        let view = ReplayPanel()
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(playerView)
        playerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 0.65).isActive = true
        if #available(iOS 11.0, *) {
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            playerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        }
        
        controlPanel.delegate = self
        playerView.addControlPanel(controlPanel)
        
        replayPanel.delegate = self
        playerView.addReplayPanel(replayPanel)
        
        let item = TrailerPlayerItem(
            url: URL(string: "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
            thumbnailUrl: URL(string: "https://upload.cc/i1/2021/10/04/qGNK3M.png"))
        playerView.playbackDelegate = self
        playerView.set(item: item)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let enableFullscreen = UIDevice.current.orientation.isLandscape
        controlPanel.fullscreenButton.isSelected = enableFullscreen
        playerView.fullscreen(enabled: enableFullscreen)
    }
}

extension ViewController: TrailerPlayerPlaybackDelegate {
    
    func trailerPlayer(_ player: TrailerPlayer, didUpdatePlaybackTime time: TimeInterval) {
        controlPanel.setProgress(withValue: time, duration: playerView.duration)
    }
    
    func trailerPlayer(_ player: TrailerPlayer, didChangePlaybackStatus status: TrailerPlayerPlaybackStatus) {
        controlPanel.setPlaybackStatus(status)
    }
}

extension ViewController: ControlPanelDelegate {
    
    func controlPanel(_ panel: ControlPanel, didTapMuteButton button: UIButton) {
        playerView.toggleMute()
        playerView.autoFadeOutControlPanelWithAnimation()
    }
    
    func controlPanel(_ panel: ControlPanel, didTapPlayPauseButton button: UIButton) {
        if playerView.status == .playing {
            playerView.pause()
        } else {
            playerView.play()
        }
        playerView.autoFadeOutControlPanelWithAnimation()
    }
    
    func controlPanel(_ panel: ControlPanel, didTapFullscreenButton button: UIButton) {
        playerView.fullscreen(enabled: button.isSelected,
                              rotateTo: button.isSelected ? .landscapeRight: .portrait)
        playerView.autoFadeOutControlPanelWithAnimation()
    }
    
    func controlPanel(_ panel: ControlPanel, didTouchDownProgressSlider slider: UISlider) {
        playerView.pause()
        playerView.cancelAutoFadeOutAnimation()
    }
    
    func controlPanel(_ panel: ControlPanel, didChangeProgressSliderValue slider: UISlider) {
        playerView.seek(to: TimeInterval(slider.value))
        playerView.play()
        playerView.autoFadeOutControlPanelWithAnimation()
    }
}

extension ViewController: ReplayPanelDelegate {
    
    func replayPanel(_ panel: ReplayPanel, didTapReplayButton: UIButton) {
        playerView.replay()
    }
}
