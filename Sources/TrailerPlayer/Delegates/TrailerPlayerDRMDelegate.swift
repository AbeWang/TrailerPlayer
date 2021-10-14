//
//  TrailerPlayerDRMDelegate.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/13.
//

import Foundation

public protocol TrailerPlayerDRMDelegate: AnyObject {
    func contentId(for player: TrailerPlayer) -> String?
    func ckcUrl(for player: TrailerPlayer) -> URL
    func certUrl(for player: TrailerPlayer) -> URL
    func ckcRequestHeaderFields(for player: TrailerPlayer) -> [(headerField: String, value: String)]?
}

public extension TrailerPlayerDRMDelegate {
    
    func contentId(for player: TrailerPlayer) -> String? {
        return nil
    }
    
    func ckcRequestHeaderFields(for player: TrailerPlayer) -> [(headerField: String, value: String)]? {
        return nil
    }
}
