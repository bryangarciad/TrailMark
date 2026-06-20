//
//  MediaMemo.swift
//  TrailmarkCore
//
//  Course 1.2 / 2.2 — the media model shared by phone and wrist.
//

import Foundation
import CoreLocation

/// The kind of media a memo holds.
public enum MemoKind: String, Codable, Sendable, CaseIterable {
    case audio
    case video

    public var symbolName: String {
        switch self {
        case .audio: return "waveform"
        case .video: return "video.fill"
        }
    }

    public var displayName: String {
        switch self {
        case .audio: return "Voice memo"
        case .video: return "Video memo"
        }
    }
}

/// Metadata for one captured memo. The actual bytes live on disk; this struct
/// only stores the file name (relative to the media directory) plus metadata.
///
/// Storing a *relative* file name rather than an absolute URL matters: the app
/// container path changes between launches and across devices, so an absolute
/// URL would dangle. `MediaStore` resolves the name to a live URL on demand.
public struct MediaMemo: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var kind: MemoKind
    /// File name relative to the media directory, e.g. "A1B2-….m4a".
    public var fileName: String
    public var createdAt: Date
    /// Duration of the recording in seconds.
    public var duration: TimeInterval
    public var title: String

    // Optional geotag (Course 1.4). Stored as primitives to keep Codable simple.
    public var latitude: Double?
    public var longitude: Double?

    public init(id: UUID = UUID(),
                kind: MemoKind,
                fileName: String,
                createdAt: Date = Date(),
                duration: TimeInterval = 0,
                title: String = "",
                latitude: Double? = nil,
                longitude: Double? = nil) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
        self.title = title.isEmpty ? Self.defaultTitle(for: kind, at: createdAt) : title
        self.latitude = latitude
        self.longitude = longitude
    }

    public var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public mutating func setCoordinate(_ coordinate: CLLocationCoordinate2D?) {
        latitude = coordinate?.latitude
        longitude = coordinate?.longitude
    }

    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }

    private static func defaultTitle(for kind: MemoKind, at date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return "\(kind.displayName) · \(df.string(from: date))"
    }
}
