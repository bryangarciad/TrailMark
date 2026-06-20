//
//  WorkoutRecord.swift
//  TrailmarkCore
//
//  Course 1.3 (write a sample workout) and 3.2 (live workout result).
//

import Foundation

/// A completed activity, ready to be written to HealthKit as an `HKWorkout`
/// and/or synced from watch to phone (Course 3.1).
public struct WorkoutRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var start: Date
    public var end: Date
    public var activeEnergyKcal: Double
    public var distanceMeters: Double
    /// Average heart rate over the session, if known.
    public var averageHeartRate: Double?

    public init(id: UUID = UUID(),
                start: Date,
                end: Date,
                activeEnergyKcal: Double = 0,
                distanceMeters: Double = 0,
                averageHeartRate: Double? = nil) {
        self.id = id
        self.start = start
        self.end = end
        self.activeEnergyKcal = activeEnergyKcal
        self.distanceMeters = distanceMeters
        self.averageHeartRate = averageHeartRate
    }

    public var duration: TimeInterval { end.timeIntervalSince(start) }

    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
}
