//
//  TrailerPlayerDRMError.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/13.
//

public enum TrailerPlayerDRMError: Error {
    case unknown
    case noRequestUrl
    case noCKCUrl
    case noCertificateData
    case noSPCData
    case noCKCData
}
