import Foundation
import CoreLocation

public struct TrackPoint: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var timestamp: Date
    
    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
    
    public init(location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            timestamp: location.timestamp
        )
    }
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


public struct RouteTrack: Hashable, Sendable, Codable {
    public var points: [TrackPoint]
    
    public init(points: [TrackPoint] = []) {
        self.points = points
    }
    
    public var coordinates: [CLLocationCoordinate2D] {
        points.map(\.coordinate)
    }
    
    public var distanceMeters: Double {
        guard points.count > 1 else { return 0 }
        var total: Double = 0
        
        for i in 1..<points.count {
            let prevLocation = CLLocation(latitude: points[i - 1].latitude, longitude: points[i - 1].longitude)
            let currentLocation = CLLocation(latitude: points[i].latitude, longitude: points[i].longitude)
            
            total += currentLocation.distance(from: prevLocation)
        }
        
        return total
    }
    
    public var altitudeGain: Double {
        guard points.count > 1 else { return 0 }
        
        var gain: Double = 0
        for index in 1..<points.count {
            let delta = points[index].altitude - points[index - 1].altitude
            if delta > 0 { gain += delta }
        }
        
        return gain
    }
    
    
    public var isEmpty: Bool { points.isEmpty }
}
