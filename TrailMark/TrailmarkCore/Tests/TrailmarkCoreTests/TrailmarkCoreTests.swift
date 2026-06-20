//
//  TrailmarkCoreTests.swift
//  TrailmarkCore
//
//  Tests for the pure, testable parts of the core — the logic that does NOT
//  need device sensors (which the curriculum notes can't be simulated).
//

import XCTest
import CoreLocation
@testable import TrailmarkCore

final class TrailmarkCoreTests: XCTestCase {

    func testRouteDistanceIsZeroForSinglePoint() {
        let track = RouteTrack(points: [TrackPoint(latitude: 37.33, longitude: -122.03)])
        XCTAssertEqual(track.distanceMeters, 0, accuracy: 0.001)
    }

    func testRouteDistanceAccumulatesAlongTrack() {
        // Two points ~1 degree of latitude apart ≈ 111 km.
        let track = RouteTrack(points: [
            TrackPoint(latitude: 37.0, longitude: -122.0),
            TrackPoint(latitude: 38.0, longitude: -122.0)
        ])
        XCTAssertEqual(track.distanceMeters, 111_000, accuracy: 2_000)
    }

    func testMemoDefaultTitleIsGenerated() {
        let memo = MediaMemo(kind: .audio, fileName: "x.m4a")
        XCTAssertFalse(memo.title.isEmpty)
    }

    func testMemoCoordinateRoundTrips() {
        var memo = MediaMemo(kind: .video, fileName: "x.mov")
        memo.setCoordinate(CLLocationCoordinate2D(latitude: 1, longitude: 2))
        XCTAssertEqual(memo.coordinate?.latitude, 1)
        XCTAssertEqual(memo.coordinate?.longitude, 2)
    }

    func testActivitySummaryCodableRoundTrip() throws {
        // Whole-second date: the .iso8601 strategy intentionally drops sub-second
        // precision, which is fine for the values we sync.
        let summary = ActivitySummary(steps: 5000, distanceMeters: 4200,
                                      activeEnergyKcal: 320,
                                      date: Date(timeIntervalSince1970: 1_700_000_000))
        let data = try JSONEncoder.trailmark.encode(summary)
        let decoded = try JSONDecoder.trailmark.decode(ActivitySummary.self, from: data)
        XCTAssertEqual(summary, decoded)
    }

    func testWorkoutDurationText() {
        let record = WorkoutRecord(start: Date(timeIntervalSince1970: 0),
                                   end: Date(timeIntervalSince1970: 3661))
        XCTAssertEqual(record.duration, 3661, accuracy: 0.001)
    }
}
