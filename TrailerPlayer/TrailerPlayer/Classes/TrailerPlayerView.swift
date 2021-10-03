//
//  TrailerPlayerView.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/9/28.
//

import Foundation
import AVFoundation
import UIKit

// TODO: SPEC
//[O] 對於沒有 trailer 的 content，就像現行 spec 一樣單純顯示 thumbnail。
//[O] 對於有 trailer 的 content，用戶進入 detail page 後，可以自動播放 trailer，且在播放途中可以隨時暫停播放。
//[O] Preview 功能不會有倍速播放功能，但是 progress bar 仍然是必須要有，而且用戶可以自由調整 progress bar 以觀看在不同秒數的內容。
//[O] Preview 功能不允許用 AirPlay 投到輸出設備上。
//[O] Preview 功能的聲音部份，預設是 off，但用戶可以點選音量按鈕，以打開聲音。 (只有開/關功能，沒有音量的 progress bar)
//[O] 對於同時有 thumbnail 與 trailer 的 content，首先一進入 detail page 時會先顯示 thumbnail，此時背景會持續 loading trailer。直到 trailer loading 完成、ready to play 的時候，即顯示 trailer 並自動播放，此時縮圖會被隱藏起來。
//[O] Preview 功能可以全螢幕播放。
//[O] Trailer 的顯示 size 會跟 thumbnail 完全一致 & 重疊。
//[O] 當 trailer 播放完畢之後，播放畫面會停止，且正中間會有一個 Replay 按鈕，用戶可以選點此按鈕以重播此 trailer。
//[O] Preview 功能的 Progress bar 的右方，會有此部 trailer 的倒數秒數，並會隨著播放而逐漸減少秒數。
//[O] 不可背景播放
//[O] 從背景回到前景時，要繼續播放
//[O] 當影片 Buffering 的時候要秀轉圈圈
//[O] trailer顯示時，要隱藏 thumbnail image
//[O] 不可在 Remote Control Center 裡顯示資訊
//[O] Preview 播完後回到 thumbnail
//[O] 如果用戶的網路，從連網 => 斷網 => 再連網的時候，trailer 會接續播放
//[] 當用戶按下 preview 鈕、並且 trailer 播放完畢之後，再回到 detail page 時，auto-preview 會再自動從頭播放
//[] Refactor code
//[] Check iOS 10~15
//[] Check leaks


public protocol TrailerPlayerViewDelegate: AnyObject {
    func trailerPlayerViewDidEndPlaying(_ view: TrailerPlayerView)
    func trailerPlayerView(_ view: TrailerPlayerView, didUpdatePlaybackTime time: TimeInterval)
}

public class TrailerPlayerView: UIView {
    
    public enum Status {
        case playing
        case pause
        case waitingToPlay
        case unknown
    }
    
    @AutoLayout
    private var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.style = .whiteLarge
        return view
    }()
    
    @AutoLayout
    private var containerView: UIView = {
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
    public var playerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.isHidden = true
        return view
    }()
    
    weak var delegate: TrailerPlayerViewDelegate?
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var currentPlayingItem: TrailerPlayerItem?
    
    private var shouldResumePlay: Bool = false
    
    private var periodicTimeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var previousTimeControlStatus: AVPlayer.TimeControlStatus?
    
    public var isMuted: Bool {
        player?.isMuted ?? true
    }
    
    public var canUseFullscreen: Bool {
        currentPlayingItem?.videoUrl != nil
    }
    
    public var duration: TimeInterval {
        guard let time = player?.currentItem?.duration else { return 0 }
        return CMTimeGetSeconds(time)
    }
    
    public var status: Status {
        guard let status = player?.timeControlStatus else { return .unknown }
        switch status {
        case .playing: return .playing
        case .paused: return .pause
        case .waitingToPlayAtSpecifiedRate: return .waitingToPlay
        default: return .unknown
        }
    }
    
    public init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        reset()
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
        
        if let url = item.videoUrl {
            setupPlayer(url)
            
            if item.autoPlay {
                player?.play()
            }
            
            player?.isMuted = item.mute
        }
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func replay() {
        player?.seek(to: CMTime.zero)
        player?.play()
        
        playerView.isHidden = false
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC)))
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
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
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
    
    func setupPlayer(_ url: URL) {
        let playerItem = AVPlayerItem(url: url)
        
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] _, _ in
            guard let self = self, let item = self.player?.currentItem else { return }
            switch item.status {
            case .readyToPlay:
                print("[TrailerPlayerView] ready to play")
                self.playerView.isHidden = false
            case .failed:
                print("[TrailerPlayerView] item failed")
            default:
                print("[TrailerPlayerView] unknown error")
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidEndPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        
        player = AVPlayer(playerItem: playerItem)
        previousTimeControlStatus = player?.timeControlStatus
        
        periodicTimeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] _ in
            guard
                let self = self,
                let player = self.player,
                player.timeControlStatus == .playing
            else { return }
            
            self.delegate?.trailerPlayerView(self, didUpdatePlaybackTime: CMTimeGetSeconds(player.currentTime()))
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
        }
        
        playerLayer = AVPlayerLayer(player: player)
        playerView.layer.addSublayer(playerLayer!)
    }
    
    func reset() {
        currentPlayingItem = nil
        
        thumbnailView.image = nil
        
        NotificationCenter.default.removeObserver(self)
        
        if let observer = periodicTimeObserver {
            player?.removeTimeObserver(observer)
            periodicTimeObserver = nil
        }
        
        statusObserver?.invalidate()
        statusObserver = nil
        
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
        
        previousTimeControlStatus = nil
        
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
    
    @objc func playerDidEndPlaying() {
        guard let item = currentPlayingItem else { return }
        
        if item.autoReplay {
            replay()
        } else {
            playerView.isHidden = true
            delegate?.trailerPlayerViewDidEndPlaying(self)
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
    
}
