import Foundation
import CoreLocation // GPS
import Observation
import ARKit

@MainActor
@Observable
public class LocationManager: NSObject {
    public internal(set) var authorizationStatus: CLAuthorizationStatus
    public internal(set) var currentLocation: CLLocation?
    public internal(set) var isTracking = false
    public internal(set) var track = RouteTrack()
    
    private let locationManager = CLLocationManager() // CLLM is a NSObj
    
    public override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        
        // Setup Settings for Core Location
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }
    
    public var currentCoordinate: CLLocationCoordinate2D? {
        currentLocation?.coordinate
    }
    
    // MARK: - Authorization Flow

    public func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func requestOneShotLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - Recording a track
    
    public func startRecording() {
        track = RouteTrack()
        isTracking = true
        // This method is the one that is going to turn the GPS tracking for continuous reading
        locationManager.startUpdatingLocation()
    }
    
    @discardableResult
    public func stopRecording() -> RouteTrack {
        isTracking = false
        locationManager.stopUpdatingLocation()
        return track
    }
}


