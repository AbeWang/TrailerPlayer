//
//  TrailerPlayerViewDRMDelegate.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/13.
//

import Foundation

public protocol TrailerPlayerViewDRMDelegate: AnyObject {
    func contentID(for playerView: TrailerPlayerView) -> String
    func certificateURL(for playerView: TrailerPlayerView) -> URL
    func contentKeyContextURL(for playerView: TrailerPlayerView) -> URL
}
