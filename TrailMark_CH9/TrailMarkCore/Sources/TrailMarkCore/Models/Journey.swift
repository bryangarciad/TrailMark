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
    
    // TODO: This will hold all the workout related data for the activity (health data)
    public var workout: Double?
    
    
    public init(
        id: UUID = UUID(),
        title: String = "Untitled Journey",
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        track: RouteTrack = RouteTrack(),
        memoIDs: [UUID] = [],
        workout: Double? = nil
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
}
