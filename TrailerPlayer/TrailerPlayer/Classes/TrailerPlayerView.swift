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
//[] 對於沒有 trailer 的 content，就像現行 spec 一樣單純顯示 thumbnail。
//[] 對於有 trailer 的 content，用戶進入 detail page 後，可以自動播放 trailer，且在播放途中可以隨時暫停播放。
//[] Preview 功能不會有倍速播放功能，但是 progress bar 仍然是必須要有，而且用戶可以自由調整 progress bar 以觀看在不同秒數的內容。
//[] Preview 功能不允許用 chromecast/AirPlay 投到輸出設備上。
//[] Preview 功能的聲音部份，預設是 off，但用戶可以點選音量按鈕，以打開聲音。 (只有開/關功能，沒有音量的 progress bar)
//[] 對於同時有 thumbnail 與 trailer 的 content，首先一進入 detail page 時會先顯示 thumbnail，此時背景會持續 loading trailer。直到 trailer loading 完成、ready to play 的時候，即顯示 trailer 並自動播放，此時縮圖會被隱藏起來。
//[] Preview 功能可以全螢幕播放。
//[] Trailer 的顯示 size 會跟 thumbnail 完全一致 & 重疊。
//[] 當 trailer 播放完畢之後，播放畫面會停止，且正中間會有一個 Replay 按鈕，用戶可以選點此按鈕以重播此 trailer。
//[] Preview 功能的 Progress bar 的右方，會有此部 trailer 的倒數秒數，並會隨著播放而逐漸減少秒數。
//[] Check iOS 11~15
//[] 不可背景播放，當從背景回到前景時，要繼續播放
//[] 不可在 Remote Control Center 裡顯示資訊

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
        playerLayer?.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem else { return }
        switch item.status {
        case .readyToPlay:
            thumbnailView.image = nil
        default:
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
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC)))
    }
    
    func toggleMute() {
        guard let player = player else { return }
        player.isMuted = !player.isMuted
    }
    
    func toggleFullscreen() {
        
    }
}

private extension TrailerPlayerView {
    
    func setupUI() {
        backgroundColor = .black
        
        addSubview(thumbnailView)
        thumbnailView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        thumbnailView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
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
        layer.addSublayer(playerLayer!)
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
    
    @objc func playerDidEndPlaying() {
        guard let item = currentPlayingItem else { return }
        
        if item.autoReplay {
            replay()
        } else {
            delegate?.trailerPlayerViewDidEndPlaying(self)
        }
    }
}
