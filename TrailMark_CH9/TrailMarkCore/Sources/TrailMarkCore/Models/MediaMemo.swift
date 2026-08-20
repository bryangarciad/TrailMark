import Foundation
import Combine
import CoreLocation

public enum MemoKind: String, Codable, Sendable, CaseIterable {
    case audio
    case video
    
    public var symbolName: String {
        switch self {
        case .audio: "waveform"
        case .video: "video.fill"
        }
    }
    
    public var displayName: String {
        switch self {
        case .audio: "Voice Memo"
        case .video: "Video Memo"
        }
    }
}

// Liskov interchage principle
public struct MediaMemo: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var kind: MemoKind
    
    public var fileName: String
    public var createdAt: Date
    
    public var duration: TimeInterval
    public var title: String
    
    public var latitude: Double?
    public var longitude: Double?
    
    public init(
        id: UUID = UUID(),
        kind: MemoKind,
        fileName: String,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        title: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
        self.title = title.isEmpty ? Self.defaultTitle(for: kind, at: createdAt) : title
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public mutating func setCoordinate(_ coordite: CLLocationCoordinate2D?) {
        latitude = coordite?.latitude
        longitude = coordite?.longitude
    }
    
    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad // 01:00
        return formatter.string(from: duration) ?? "00:00"
    }
    
    private static func defaultTitle(for kind: MemoKind, at date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        
        return "\(kind.displayName)-\(df.string(from: date))" // Voice Memo-08-17-2026T19:08
    }
}
