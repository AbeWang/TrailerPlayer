//
//  TrailerPlayerViewPlaybackDelegate.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/12.
//

import Foundation

public protocol TrailerPlayerViewPlaybackDelegate: AnyObject {
    func trailerPlayerViewDidEndPlaying(_ view: TrailerPlayerView)
    func trailerPlayerView(_ view: TrailerPlayerView, didUpdatePlaybackTime time: TimeInterval)
    func trailerPlayerView(_ view: TrailerPlayerView, didChangePlaybackStatus status: TrailerPlayerPlaybackStatus)
    func trailerPlayerViewReadyToPlay(_ view: TrailerPlayerView)
    func trailerPlayerView(_ view: TrailerPlayerView, playbackDidFailed error: TrailerPlayerPlaybackError)
}

public extension TrailerPlayerViewPlaybackDelegate {
    
    func trailerPlayerViewDidEndPlaying(_ view: TrailerPlayerView) {}
    
    func trailerPlayerView(_ view: TrailerPlayerView, didUpdatePlaybackTime time: TimeInterval) {}
    
    func trailerPlayerView(_ view: TrailerPlayerView, didChangePlaybackStatus status: TrailerPlayerPlaybackStatus) {}
    
    func trailerPlayerViewReadyToPlay(_ view: TrailerPlayerView) {}
    
    func trailerPlayerView(_ view: TrailerPlayerView, playbackDidFailed error: TrailerPlayerPlaybackError) {}
}
