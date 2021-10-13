//
//  TrailerPlayerViewDRMDelegate.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/13.
//

import Foundation

public protocol TrailerPlayerViewDRMDelegate: AnyObject {
    func contentID(for playerView: TrailerPlayerView) -> String?
    func certificateURL(for playerView: TrailerPlayerView) -> URL
    func contentKeyContextURL(for playerView: TrailerPlayerView) -> URL
    func ckcRequestHeaderFields(for playerView: TrailerPlayerView) -> [(headerField: String, value: String)]?
}

public extension TrailerPlayerViewDRMDelegate {
    
    func contentID(for playerView: TrailerPlayerView) -> String? {
        return nil
    }
    
    func ckcRequestHeaderFields(for playerView: TrailerPlayerView) -> [(headerField: String, value: String)]? {
        return nil
    }
}
