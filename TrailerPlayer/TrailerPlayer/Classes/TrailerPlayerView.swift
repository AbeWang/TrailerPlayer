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
//[] 從背景回到前景時，要繼續播放
//[] 當影片 Buffering 的時候要秀轉圈圈
//[] trailer顯示時，要隱藏 thumbnail image
//[O] 不可在 Remote Control Center 裡顯示資訊
//[O] Preview 播完後回到 thumbnail
//[O] 如果用戶的網路，從連網 => 斷網 => 再連網的時候，trailer 會接續播放
//[] 當用戶按下 preview 鈕、並且 trailer 播放完畢之後，再回到 detail page 時，auto-preview 會再自動從頭播放
//[] Refactor code
//[] Check iOS 10~15


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
        view.style = .white
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
    public var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.isHidden = true
        return view
    }()
    
    weak var delegate: TrailerPlayerViewDelegate?
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var currentPlayingItem: TrailerPlayerItem?
    
    public var isMuted: Bool {
        player?.isMuted ?? true
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
        setupUI()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        reset()
    }
    
    public override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        playerLayer?.frame = CGRect(x: 0.0, y: 0.0, width: contentView.frame.width, height: contentView.frame.height)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem else { return }
        switch item.status {
        case .readyToPlay:
            contentView.isHidden = false
        default:
            print("[ERROR] TrailerPlayerView item status : \(item.status)")
            break
        }
    }
}

public extension TrailerPlayerView {
    
    func set(item: TrailerPlayerItem) {
        reset()
        
        currentPlayingItem = item
        
        if let url = item.thumbnailUrl {
            loadingIndicator.startAnimating()
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
        
        contentView.isHidden = false
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC)))
    }
    
    func toggleMute() {
        guard let player = player else { return }
        player.isMuted = !player.isMuted
    }
    
    func fullscreen(enabled: Bool, rotateTo orientation: UIInterfaceOrientation? = nil) {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        contentView.removeFromSuperview()

        layout(view: contentView, into: enabled ? window: self)
        
        if let orientation = orientation {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }
}

private extension TrailerPlayerView {
    
    func setupUI() {
        backgroundColor = .black
        
        layout(view: thumbnailView, into: self, animated: false)
        
        addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        layout(view: contentView, into: self, animated: false)
    }
    
    func fetchThumbnailImage(_ url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                guard let data = data, error == nil else { return }
                UIView.transition(with: self.thumbnailView, duration: 0.25, options: .transitionCrossDissolve) {
                    self.thumbnailView.image = UIImage(data: data)
                } completion: {_ in }
            }
        }
        .resume()
    }
    
    func setupPlayer(_ url: URL) {
        let playerItem = AVPlayerItem(url: url)
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidEndPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        
        player = AVPlayer(playerItem: playerItem)
        player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] _ in
            guard
                let self = self,
                let player = self.player,
                player.timeControlStatus == .playing
            else { return }
            
            self.delegate?.trailerPlayerView(self, didUpdatePlaybackTime: CMTimeGetSeconds(player.currentTime()))
        }
        
        playerLayer = AVPlayerLayer(player: player)
        contentView.layer.addSublayer(playerLayer!)
    }
    
    func reset() {
        currentPlayingItem = nil
        
        thumbnailView.image = nil
        
        NotificationCenter.default.removeObserver(self)
        
        player?.pause()
        player?.currentItem?.removeObserver(self, forKeyPath: "status")
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
            contentView.isHidden = true
            delegate?.trailerPlayerViewDidEndPlaying(self)
        }
    }
}
