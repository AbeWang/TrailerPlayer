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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(playerView)
        playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        playerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 0.65).isActive = true
        
        view.addSubview(muteButton)
        muteButton.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 20.0).isActive = true
        muteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        muteButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        muteButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        view.addSubview(playPauseButton)
        playPauseButton.topAnchor.constraint(equalTo: muteButton.bottomAnchor, constant: 20.0).isActive = true
        playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        playPauseButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        playPauseButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        view.addSubview(fullscreenButton)
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
        
        let item = TrailerPlayerItem(
            url: URL(string: "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
            thumbnailUrl: URL(string: "https://img.ltn.com.tw/Upload/news/600/2019/03/30/phpUCF6ub.jpg"))
        playerView.set(item: item)
    }
}
