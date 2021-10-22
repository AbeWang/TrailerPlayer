//
//  TrailerPlayerItem.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/1.
//

import Foundation
import UIKit

public class TrailerPlayerItem {
    public let videoUrl: URL?
    public let thumbnailUrl: URL?
    public let thumbnailImage: UIImage?
    public let autoPlay: Bool
    public let autoReplay: Bool
    public let mute: Bool
    public let isDRMContent: Bool
    
    required public init(url: URL? = nil,
                         thumbnailUrl: URL? = nil,
                         thumbnailImage: UIImage? = nil,
                         autoPlay: Bool = true,
                         autoReplay: Bool = false,
                         mute: Bool = true,
                         isDRMContent: Bool = false) {
        self.videoUrl = url
        self.thumbnailUrl = thumbnailUrl
        self.thumbnailImage = thumbnailImage
        self.autoPlay = autoPlay
        self.autoReplay = autoReplay
        self.mute = mute
        self.isDRMContent = isDRMContent
    }
}
