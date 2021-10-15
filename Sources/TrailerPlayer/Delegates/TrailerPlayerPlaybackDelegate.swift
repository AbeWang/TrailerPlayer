//
//  TrailerPlayerPlaybackDelegate.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/12.
//

import Foundation

public protocol TrailerPlayerPlaybackDelegate: AnyObject {
    func trailerPlayerPlaybackReady(_ player: TrailerPlayer)
    func trailerPlayer(_ player: TrailerPlayer, didUpdatePlaybackTime time: TimeInterval)
    func trailerPlayer(_ player: TrailerPlayer, didChangePlaybackStatus status: TrailerPlayerPlaybackStatus)
    func trailerPlayer(_ player: TrailerPlayer, playbackDidFailed error: TrailerPlayerPlaybackError)
}

public extension TrailerPlayerPlaybackDelegate {
    
    func trailerPlayerPlaybackReady(_ player: TrailerPlayer) {}
    
    func trailerPlayer(_ player: TrailerPlayer, didUpdatePlaybackTime time: TimeInterval) {}
    
    func trailerPlayer(_ player: TrailerPlayer, didChangePlaybackStatus status: TrailerPlayerPlaybackStatus) {}
    
    func trailerPlayer(_ player: TrailerPlayer, playbackDidFailed error: TrailerPlayerPlaybackError) {}
}
