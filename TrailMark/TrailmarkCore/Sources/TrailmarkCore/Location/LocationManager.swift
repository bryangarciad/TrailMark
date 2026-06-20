//
//  LocationManager.swift
//  TrailmarkCore
//
//  Course 1.4 — the route engine. Requests when-in-use authorization, records
//  a coordinate track, and exposes the current coordinate for geotagging memos.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate {

    public private(set) var authorizationStatus: CLAuthorizationStatus
    public private(set) var currentLocation: CLLocation?
    public private(set) var isRecording = false
    /// The track recorded since `startRecording()` was last called.
    public private(set) var track = RouteTrack()

    private let manager = CLLocationManager()

    public override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        // 10m filter keeps the track readable and is gentle on the battery —
        // the power conversation Course 3.3 picks up.
        manager.distanceFilter = 10
    }

    public var currentCoordinate: CLLocationCoordinate2D? {
        currentLocation?.coordinate
    }

    // MARK: - Authorization

    public func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// A one-shot location request, handy for geotagging a memo right now.
    public func requestOneShotLocation() {
        manager.requestLocation()
    }

    // MARK: - Recording a track

    public func startRecording() {
        track = RouteTrack()
        isRecording = true
        manager.startUpdatingLocation()
    }

    @discardableResult
    public func stopRecording() -> RouteTrack {
        isRecording = false
        manager.stopUpdatingLocation()
        return track
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated public func locationManager(_ manager: CLLocationManager,
                                            didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager,
                                            didUpdateLocations locations: [CLLocation]) {
        let points = locations.map(TrackPoint.init(location:))
        let last = locations.last
        Task { @MainActor in
            self.currentLocation = last
            if self.isRecording {
                self.track.points.append(contentsOf: points)
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager,
                                            didFailWithError error: Error) {
        // Location failures are common and transient (e.g. no fix indoors).
        // We swallow them so the UI keeps whatever track it has.
    }
}
