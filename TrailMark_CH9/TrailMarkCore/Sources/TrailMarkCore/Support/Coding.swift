import Foundation

// Shared JSON coders with a stable date strategy. The media index, the journey
// store and the WatchConnectivity payloads all go through these, so every layer
// agrees on how a Date looks on the wire.

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
