import Foundation
import CoreLocation

// MARK: - Mock Building Blocks
extension TrackPoint {
    static func mockID(_ index: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index)) ?? UUID()
    }
}

extension RouteTrack {
    public static let mockStartDate = Date(timeIntervalSince1970: 1_785_983_510)
    
    public struct MockWayPoint: Sendable {
        public var latitude: Double
        public var longitude: Double
        public var altitude: Double
        
        public init(_ latitude: Double, _ longitude: Double, _ altitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
            self.altitude = altitude
        }
    }
    
    public static func mock(
        waypoints: [MockWayPoint],
        samplesPerSegment: Int = 12,
        start: Date = RouteTrack.mockStartDate,
        sampleInterval: TimeInterval = 5
    ) -> RouteTrack {
        guard let first = waypoints.first else { return RouteTrack() }
        guard waypoints.count > 1, samplesPerSegment > 0 else {
            return RouteTrack(points: [
                TrackPoint(
                    id: TrackPoint.mockID(0),
                    latitude: first.latitude,
                    longitude: first.longitude,
                    altitude: first.altitude,
                    timestamp: start
                )
            ])
        }
        
        var points: [TrackPoint] = []
        
        // This will give us an array with N-1 elements
        for (segmentIndex, origin) in waypoints.dropLast().enumerated() {
            let destination = waypoints[segmentIndex + 1]
            // dropLast() means segmentIndex tops out at count - 2, so that's the final segment.
            // Only it appends the closing waypoint; the others stop one short to avoid
            // duplicating the point they share with the next segment.
            let isFinalSegment = segmentIndex == waypoints.count - 2
            let stepCount = isFinalSegment ? samplesPerSegment : samplesPerSegment - 1

            for steps in 0...stepCount {
                let progress = Double(steps) / Double(samplesPerSegment)
                let index = points.count

                points.append(
                    TrackPoint(
                        id: TrackPoint.mockID(index),
                        latitude: origin.latitude + (destination.latitude - origin.latitude) * progress,
                        longitude: origin.longitude + (destination.longitude - origin.longitude) * progress,
                        altitude: origin.altitude + (destination.altitude - origin.altitude) * progress,
                        timestamp: start.addingTimeInterval(Double(index) * sampleInterval)
                    )
                )
            }
        }
        
        return RouteTrack(points: points)
    }
}

extension RouteTrack {
    /// Flat loop through Golden Gate Park, San Francisco.
    /// 85 points, ~2.5 km, 42–51 m altitude, ~31 min at a 4.9 km/h walking pace.
    /// Good default for a "typical journey" row or map snapshot.
    public static let mockParkLoop = RouteTrack.mock(
        waypoints: [
            MockWayPoint(37.769_420, -122.483_000, 42),
            MockWayPoint(37.770_180, -122.478_400, 45),
            MockWayPoint(37.771_050, -122.473_900, 48),
            MockWayPoint(37.770_600, -122.469_500, 51),
            MockWayPoint(37.768_900, -122.470_800, 47),
            MockWayPoint(37.768_300, -122.476_200, 44),
            MockWayPoint(37.769_420, -122.483_000, 42)
        ],
        samplesPerSegment: 14,
        sampleInterval: 22
    )

    /// Climb up the Mount Tamalpais ridge, so elevation charts and "highest point" style stats
    /// have something interesting to show.
    /// 109 points, ~3.1 km, 128 m climbing to 607 m, ~54 min at a 3.5 km/h hiking pace.
    public static let mockRidgeHike = RouteTrack.mock(
        waypoints: [
            MockWayPoint(37.905_600, -122.606_800, 128),
            MockWayPoint(37.908_900, -122.601_400, 214),
            MockWayPoint(37.912_300, -122.598_100, 305),
            MockWayPoint(37.914_800, -122.592_600, 388),
            MockWayPoint(37.918_200, -122.589_300, 462),
            MockWayPoint(37.921_400, -122.584_700, 541),
            MockWayPoint(37.923_100, -122.579_900, 607)
        ],
        samplesPerSegment: 18,
        sampleInterval: 30
    )

    /// Coastal run along the Great Highway — nearly a straight line, useful for checking how a
    /// long thin route frames on a map.
    /// 81 points, ~2.8 km, 8–12 m altitude, ~17 min at a 9.8 km/h running pace.
    public static let mockCoastalRun = RouteTrack.mock(
        waypoints: [
            MockWayPoint(37.760_100, -122.510_800, 9),
            MockWayPoint(37.766_400, -122.511_200, 11),
            MockWayPoint(37.772_900, -122.511_600, 8),
            MockWayPoint(37.779_300, -122.511_100, 12),
            MockWayPoint(37.785_600, -122.510_400, 10)
        ],
        samplesPerSegment: 20,
        sampleInterval: 13
    )

    /// Recording just started: one point, zero distance. Exercises the "no route yet" layout.
    public static let mockJustStarted = RouteTrack.mock(
        waypoints: [MockWayPoint(37.769_420, -122.483_000, 42)]
    )

    /// Nothing recorded at all. Exercises empty states and placeholder maps.
    public static let mockEmpty = RouteTrack()

    /// Every non-empty sample track, handy for driving a `List` or a `ForEach` in a preview.
    public static let mockAll: [RouteTrack] = [
        .mockParkLoop,
        .mockRidgeHike,
        .mockCoastalRun,
        .mockJustStarted
    ]
}
