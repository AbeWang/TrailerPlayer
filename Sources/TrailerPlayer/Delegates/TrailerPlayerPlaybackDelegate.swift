//
//  TrailerPlayerPlaybackDelegate.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/12.
//

import Foundation

public protocol TrailerPlayerPlaybackDelegate: AnyObject {
    func trailerPlayer(_ player: TrailerPlayer, didUpdatePlaybackTime time: TimeInterval)
    func trailerPlayer(_ player: TrailerPlayer, didChangePlaybackStatus status: TrailerPlayerPlaybackStatus)
    func trailerPlayerReadyToPlay(_ player: TrailerPlayer)
    func trailerPlayer(_ player: TrailerPlayer, playbackDidFailed error: TrailerPlayerPlaybackError)
    func trailerPlayer(_ player: TrailerPlayer, isBuffering: Bool)
}

public extension TrailerPlayerPlaybackDelegate {
    
    func trailerPlayer(_ player: TrailerPlayer, didUpdatePlaybackTime time: TimeInterval) {}
    
    func trailerPlayer(_ player: TrailerPlayer, didChangePlaybackStatus status: TrailerPlayerPlaybackStatus) {}
    
    func trailerPlayerReadyToPlay(_ player: TrailerPlayer) {}
    
    func trailerPlayer(_ player: TrailerPlayer, playbackDidFailed error: TrailerPlayerPlaybackError) {}
    
    func trailerPlayer(_ player: TrailerPlayer, isBuffering: Bool) {}
}
