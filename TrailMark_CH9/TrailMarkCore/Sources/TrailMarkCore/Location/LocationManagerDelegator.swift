import Foundation
import CoreLocation // GPS
import Observation


// MARK: - Location Manager Extension For Event Delegation
extension LocationManager: CLLocationManagerDelegate {
    nonisolated public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocation locations: [CLLocation]) {
        let points = locations.map(TrackPoint.init(location:))
        let last = locations.last
        Task { @MainActor in
            self.currentLocation = last
            if self.isTracking {
                self.track.points.append(contentsOf: points)
            }
        }
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location failures are common and transient (e.g. fix indoors)
        // We swallow them so the UI keeps track of the events
    }
}
