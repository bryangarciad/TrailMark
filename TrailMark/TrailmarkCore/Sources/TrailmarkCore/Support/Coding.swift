//
//  Coding.swift
//  TrailmarkCore
//
//  Shared JSON coders with a stable date strategy. Used by the media index,
//  the journey store, and WatchConnectivity payloads so every layer agrees.
//

import Foundation

public extension JSONEncoder {
    static let trailmark: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}

public extension JSONDecoder {
    static let trailmark: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
