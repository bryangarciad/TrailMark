//
//  RouteTrack+Mock.swift
//  TrailMarkCore
//
//  Sample tracks for SwiftUI previews and manual testing.
//  Everything here is deterministic: same coordinates, timestamps and IDs on
//  every launch, so previews never shift between runs.
//

import Foundation
import CoreLocation

// MARK: - Mock Building Blocks

extension TrackPoint {
    /// Stable ID so SwiftUI keeps the same identity across preview reloads.
    static func mockID(_ index: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index)) ?? UUID()
    }
}

extension RouteTrack {
    /// A single fixed moment in time (2026-08-01 09:00 UTC) that every mock track starts from.
    public static let mockStartDate = Date(timeIntervalSince1970: 1_785_574_800)

    /// A hand-written waypoint: the shape of a route before it gets filled in with samples.
    public struct MockWaypoint: Sendable {
        public var latitude: Double
        public var longitude: Double
        public var altitude: Double

        public init(_ latitude: Double, _ longitude: Double, _ altitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
            self.altitude = altitude
        }
    }

    /// Walks the waypoints and drops evenly spaced samples between each pair, so a handful of
    /// corners turns into a dense line that looks like a real GPS recording on a map.
    ///
    /// - Parameters:
    ///   - waypoints: The corners of the route, in the order they were travelled.
    ///   - samplesPerSegment: How many points to place between two waypoints.
    ///   - start: Timestamp of the first point.
    ///   - sampleInterval: Seconds between consecutive points.
    public static func mock(
        waypoints: [MockWaypoint],
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

        for (segmentIndex, origin) in waypoints.dropLast().enumerated() {
            let destination = waypoints[segmentIndex + 1]
            let isFinalSegment = segmentIndex == waypoints.count - 2

            // Include the closing waypoint only once, on the last segment.
            let stepCount = isFinalSegment ? samplesPerSegment : samplesPerSegment - 1

            for step in 0...stepCount {
                let progress = Double(step) / Double(samplesPerSegment)
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

// MARK: - Sample Tracks

extension RouteTrack {

    /// Flat loop through Golden Gate Park, San Francisco.
    /// 85 points, ~2.5 km, 42–51 m altitude, ~31 min at a 4.9 km/h walking pace.
    /// Good default for a "typical journey" row or map snapshot.
    public static let mockParkLoop = RouteTrack.mock(
        waypoints: [
            MockWaypoint(37.769_420, -122.483_000, 42),
            MockWaypoint(37.770_180, -122.478_400, 45),
            MockWaypoint(37.771_050, -122.473_900, 48),
            MockWaypoint(37.770_600, -122.469_500, 51),
            MockWaypoint(37.768_900, -122.470_800, 47),
            MockWaypoint(37.768_300, -122.476_200, 44),
            MockWaypoint(37.769_420, -122.483_000, 42)
        ],
        samplesPerSegment: 14,
        sampleInterval: 22
    )

    /// Climb up the Mount Tamalpais ridge, so elevation charts and "highest point" style stats
    /// have something interesting to show.
    /// 109 points, ~3.1 km, 128 m climbing to 607 m, ~54 min at a 3.5 km/h hiking pace.
    public static let mockRidgeHike = RouteTrack.mock(
        waypoints: [
            MockWaypoint(37.905_600, -122.606_800, 128),
            MockWaypoint(37.908_900, -122.601_400, 214),
            MockWaypoint(37.912_300, -122.598_100, 305),
            MockWaypoint(37.914_800, -122.592_600, 388),
            MockWaypoint(37.918_200, -122.589_300, 462),
            MockWaypoint(37.921_400, -122.584_700, 541),
            MockWaypoint(37.923_100, -122.579_900, 607)
        ],
        samplesPerSegment: 18,
        sampleInterval: 30
    )

    /// Coastal run along the Great Highway — nearly a straight line, useful for checking how a
    /// long thin route frames on a map.
    /// 81 points, ~2.8 km, 8–12 m altitude, ~17 min at a 9.8 km/h running pace.
    public static let mockCoastalRun = RouteTrack.mock(
        waypoints: [
            MockWaypoint(37.760_100, -122.510_800, 9),
            MockWaypoint(37.766_400, -122.511_200, 11),
            MockWaypoint(37.772_900, -122.511_600, 8),
            MockWaypoint(37.779_300, -122.511_100, 12),
            MockWaypoint(37.785_600, -122.510_400, 10)
        ],
        samplesPerSegment: 20,
        sampleInterval: 13
    )

    /// Recording just started: one point, zero distance. Exercises the "no route yet" layout.
    public static let mockJustStarted = RouteTrack.mock(
        waypoints: [MockWaypoint(37.769_420, -122.483_000, 42)]
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


