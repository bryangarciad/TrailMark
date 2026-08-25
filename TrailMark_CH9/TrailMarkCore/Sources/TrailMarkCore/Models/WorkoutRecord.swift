import Foundation

public struct WorkoutRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var start: Date
    public var end: Date
    public var activeEnergyKcal: Double?
    public var distaceMeters: Double
    public var avaregeHeartRate: Double?
    
    public init(
        id: UUID = UUID(),
        start: Date,
        end: Date,
        activceEnergyKcal: Double = 0,
        distanceMeters: Double = 0,
        averageHeartRate: Double? = nil
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.activeEnergyKcal = activceEnergyKcal
        self.distaceMeters = distanceMeters
        self.avaregeHeartRate = averageHeartRate
    }
    
    public var duration: TimeInterval { end.timeIntervalSince(start) }
    
    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}
