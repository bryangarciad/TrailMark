import Foundation


// Adventure Struct: Where you went, how you moved, how that affected your health and everything you capture
public struct Journey: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let title: String
    public let startedAt: Date
    public let endedAt: Date?
    
    // The recorded coordinate track
    /// [(altitude, longitude, latitude), ....]
    public var track: RouteTrack
    
    // IDs for audio memos (storing the references for the files)
    public var memoIDs: [UUID]
    
    // The activity totals, if a workout was recorded alongside the route
    public var workout: WorkoutRecord?


    public init(
        id: UUID = UUID(),
        title: String = "Untitled Journey",
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        track: RouteTrack = RouteTrack(),
        memoIDs: [UUID] = [],
        workout: WorkoutRecord? = nil
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.track = track
        self.memoIDs = memoIDs
        self.workout = workout
    }
    
    // MARK: - Computed Properties

    /// Prefer the workout's own distance when there is one — HealthKit measures it
    /// better than summing GPS points does.
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
