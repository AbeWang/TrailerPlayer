//
//  ControlPanel.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/8.
//

import UIKit

protocol ControlPanelDelegate: AnyObject {
    func controlPanel(_ panel: ControlPanel, didTapMuteButton button: UIButton)
    func controlPanel(_ panel: ControlPanel, didTapPlayPauseButton button: UIButton)
    func controlPanel(_ panel: ControlPanel, didTapFullscreenButton button: UIButton)
    func controlPanel(_ panel: ControlPanel, didTouchDownProgressSlider slider: UISlider)
    func controlPanel(_ panel: ControlPanel, didChangeProgressSliderValue slider: UISlider)
}

class ControlPanel: UIView {

    weak var delegate: ControlPanelDelegate?
    
    private var timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    @AutoLayout
    var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.isSelected = true
        button.setImage(UIImage(named: "audio")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "no-audio")?.withRenderingMode(.alwaysTemplate), for: .selected)
        return button
    }()
    
    @AutoLayout
    var playPauseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.isSelected = false
        button.setImage(UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "play")?.withRenderingMode(.alwaysTemplate), for: .selected)
        return button
    }()
    
    @AutoLayout
    var fullscreenButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.setImage(UIImage(named: "fullscreen")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "normal-screen")?.withRenderingMode(.alwaysTemplate), for: .selected)
        return button
    }()
    
    @AutoLayout
    var countDownLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    @AutoLayout
    var progressView: UISlider = {
        let view = UISlider()
        view.isContinuous = false
        view.thumbTintColor = .red
        view.tintColor = .red
        view.value = 0.0
        view.minimumValue = 0.0
        return view
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ControlPanel {

    func setProgress(withValue value: TimeInterval, duration: TimeInterval) {
        progressView.value = Float(value)
        progressView.maximumValue = Float(duration)
        countDownLabel.text = timeFormatter.string(from: duration - value)
    }
    
    func setPlaybackStatus(_ status: TrailerPlayerPlaybackStatus) {
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

private extension ControlPanel {
    
    func setup() {
        backgroundColor = .black.withAlphaComponent(0.5)
        
        addSubview(playPauseButton)
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        playPauseButton.widthAnchor.constraint(equalToConstant: 60.0).isActive = true
        playPauseButton.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        
        addSubview(fullscreenButton)
        fullscreenButton.addTarget(self, action: #selector(didTapFullscreen), for: .touchUpInside)
        fullscreenButton.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        fullscreenButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        if #available(iOS 11.0, *) {
            fullscreenButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
            fullscreenButton.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -10.0).isActive = true
        } else {
            fullscreenButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            fullscreenButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -10.0).isActive = true
        }
        
        addSubview(muteButton)
        muteButton.addTarget(self, action: #selector(didTapMute), for: .touchUpInside)
        muteButton.bottomAnchor.constraint(equalTo: fullscreenButton.topAnchor).isActive = true
        muteButton.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        muteButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        if #available(iOS 11.0, *) {
            muteButton.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -10.0).isActive = true
        } else {
            muteButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -10.0).isActive = true
        }
        
        addSubview(countDownLabel)
        countDownLabel.rightAnchor.constraint(equalTo: fullscreenButton.leftAnchor).isActive = true
        countDownLabel.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        countDownLabel.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        if #available(iOS 11.0, *) {
            countDownLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            countDownLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        
        addSubview(progressView)
        progressView.addTarget(self, action: #selector(didChangePlaybackTime), for: .valueChanged)
        progressView.addTarget(self, action: #selector(didTouchDownProgressSlider), for: .touchDown)
        progressView.rightAnchor.constraint(equalTo: countDownLabel.leftAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        if #available(iOS 11.0, *) {
            progressView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 10.0).isActive = true
            progressView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            progressView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10.0).isActive = true
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
    }
    
    @objc func didTapPlayPause() {
        delegate?.controlPanel(self, didTapPlayPauseButton: playPauseButton)
    }
    
    @objc func didTapFullscreen() {
        fullscreenButton.isSelected = !fullscreenButton.isSelected
        delegate?.controlPanel(self, didTapFullscreenButton: fullscreenButton)
    }
    
    @objc func didTapMute() {
        muteButton.isSelected = !muteButton.isSelected
        delegate?.controlPanel(self, didTapMuteButton: muteButton)
    }
    
    @objc func didChangePlaybackTime() {
        delegate?.controlPanel(self, didChangeProgressSliderValue: progressView)
    }
    
    @objc func didTouchDownProgressSlider() {
        delegate?.controlPanel(self, didTouchDownProgressSlider: progressView)
    }
}
