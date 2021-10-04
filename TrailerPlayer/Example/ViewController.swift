//
//  ViewController.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/9/28.
//

import UIKit

class ViewController: UIViewController {

    @AutoLayout
    private var playerView = TrailerPlayerView()
    
    @AutoLayout
    private var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Mute", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .highlighted)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 5.0
        return button
    }()
    
    @AutoLayout
    private var playPauseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Play / Pause", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .highlighted)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 5.0
        return button
    }()
    
    @AutoLayout
    private var fullscreenButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Fullscreen", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .highlighted)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 5.0
        return button
    }()
    
    @AutoLayout
    private var countDownLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 24.0)
        label.textColor = .black
        label.numberOfLines = 2
        return label
    }()
    
    @AutoLayout
    private var progressView: UISlider = {
        let view = UISlider()
        view.isContinuous = false
        view.value = 0.0
        view.minimumValue = 0.0
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(playerView)
        playerView.delegate = self
        playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        playerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 0.65).isActive = true
        
        view.addSubview(muteButton)
        muteButton.addTarget(self, action: #selector(didTapMute), for: .touchUpInside)
        muteButton.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 20.0).isActive = true
        muteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        muteButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        muteButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        view.addSubview(playPauseButton)
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        playPauseButton.topAnchor.constraint(equalTo: muteButton.bottomAnchor, constant: 20.0).isActive = true
        playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        playPauseButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        playPauseButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        view.addSubview(fullscreenButton)
        fullscreenButton.addTarget(self, action: #selector(didTapFullscreen), for: .touchUpInside)
        fullscreenButton.topAnchor.constraint(equalTo: playPauseButton.bottomAnchor, constant: 20.0).isActive = true
        fullscreenButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        fullscreenButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        fullscreenButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        view.addSubview(countDownLabel)
        countDownLabel.text = "Countdown timer:\n 0"
        countDownLabel.topAnchor.constraint(equalTo: fullscreenButton.bottomAnchor, constant: 20.0).isActive = true
        countDownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        countDownLabel.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        countDownLabel.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        
        view.addSubview(progressView)
        progressView.addTarget(self, action: #selector(didChangePlaybackTime), for: .valueChanged)
        progressView.addTarget(self, action: #selector(didTouchProgress), for: .touchDown)
        progressView.topAnchor.constraint(equalTo: countDownLabel.bottomAnchor, constant: 20.0).isActive = true
        progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        progressView.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        
        let item = TrailerPlayerItem(
            url: URL(string: "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
            thumbnailUrl: URL(string: "https://upload.cc/i1/2021/10/04/qGNK3M.png"))
        playerView.set(item: item)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        playerView.fullscreen(enabled: UIDevice.current.orientation.isLandscape)
    }
}

extension ViewController {
    
    @objc func didTapMute() {
        playerView.toggleMute()
    }
    
    @objc func didTapPlayPause() {
        if playerView.status == .playing {
            playerView.pause()
        } else {
            playerView.play()
        }
    }
    
    @objc func didTapFullscreen() {
        guard playerView.canUseFullscreen else {
            let controller = UIAlertController(title: "No trailer video url", message: nil, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            present(controller, animated: true, completion: nil)
            return
        }
        playerView.fullscreen(enabled: true, rotateTo: .landscapeRight)
    }
    
    @objc func didChangePlaybackTime() {
        playerView.seek(to: TimeInterval(progressView.value))
        playerView.play()
    }
    
    @objc func didTouchProgress() {
        playerView.pause()
    }
    
}

extension ViewController: TrailerPlayerViewDelegate {
    
    func trailerPlayerViewDidEndPlaying(_ view: TrailerPlayerView) {
        let controller = UIAlertController(title: "End", message: nil, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Replay", style: .default, handler: { _ in
            view.replay()
        }))
        controller.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    func trailerPlayerView(_ view: TrailerPlayerView, didUpdatePlaybackTime time: TimeInterval) {
        countDownLabel.text = "Countdown timer:\n \(Int(playerView.duration - time))"
        
        progressView.value = Float(time)
        progressView.maximumValue = Float(playerView.duration)
    }
    
}
