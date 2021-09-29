//
//  TrailerPlayerItem.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/9/28.
//

import Foundation

public class TrailerPlayerItem {
    public let videoUrl: URL?
    public let thumbnailUrl: URL?
    public let autoPlay: Bool
    public let autoReplay: Bool
    public let mute: Bool
    
    required public init(url: URL? = nil,
                         thumbnailUrl: URL? = nil,
                         autoPlay: Bool = true,
                         autoReplay: Bool = false,
                         mute: Bool = true) {
        self.videoUrl = url
        self.thumbnailUrl = thumbnailUrl
        self.autoPlay = autoPlay
        self.autoReplay = autoReplay
        self.mute = mute
    }
}
