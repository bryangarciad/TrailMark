//
//  Journey.swift
//  TrailmarkCore
//
//  Course 1.4 — the unified record that ties route + health + media together,
//  and the payload synced wrist→pocket in Course 3.1.
//

import Foundation

/// One adventure: where you went, how you moved, and what you captured.
public struct Journey: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var title: String
    public var startedAt: Date
    public var endedAt: Date?

    /// The recorded coordinate track.
    public var track: RouteTrack
    /// IDs of memos captured during this journey (resolved via `MediaStore`).
    public var memoIDs: [UUID]
    /// The activity totals, if a workout was recorded.
    public var workout: WorkoutRecord?

    public init(id: UUID = UUID(),
                title: String = "Untitled journey",
                startedAt: Date = Date(),
                endedAt: Date? = nil,
                track: RouteTrack = RouteTrack(),
                memoIDs: [UUID] = [],
                workout: WorkoutRecord? = nil) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.track = track
        self.memoIDs = memoIDs
        self.workout = workout
    }

    public var distanceMeters: Double {
        workout?.distanceMeters ?? track.distanceMeters
    }

    public var dateText: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: startedAt)
    }
}
