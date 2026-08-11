import SwiftUI
import MapKit
import TrailMarkCore

struct RouteMapView: View {
    let track: RouteTrack
    
    var lineWidth: CGFloat = 5
    var showsEndpoints: Bool = true
    
    @State private var camera: MapCameraPosition = .automatic
    
    var body: some View {
        if track.isEmpty {
            ContentUnavailableView(
                "No Route Recorded",
                systemImage: "map",
                description: Text("Start a journey to see it here.")
            )
        } else {
            Map(position: $camera) {
                if track.points.count > 1 {
                    // layer 1
                    MapPolyline(coordinates: track.coordinates)
                        .stroke(.red.opacity(0.7), style: StrokeStyle(lineWidth: lineWidth + 5, lineCap: .round, lineJoin: .round))
                    
                    // layer 2
                    MapPolyline(coordinates: track.coordinates)
                        .stroke(.blue, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                }
                
                if showsEndpoints {
                    if let start = track.points.first {
                        Annotation("Start", coordinate: start.coordinate) {
                            Image(systemName: "flag.fill")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(.green, in: .circle)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .shadow(radius: 2, y: 1)
                        }
                    }
                    
                    if let end = track.points.last, track.points.count > 1 {
                        Annotation("Finish", coordinate: end.coordinate) {
                            Image(systemName: "flag.checkered")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(.red, in: .circle)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .shadow(radius: 2, y: 1)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .task(id: track) {
                camera  = Self.cameraPosition(for: track)
            }
            
        }
    }
    
    /// Frames the camera around the whole route, with a little breathing room so the line and
    /// the endpoint markers aren't flush against the edges.
    static func cameraPosition(for track: RouteTrack) -> MapCameraPosition {
        let coordinates = track.coordinates

        guard let first = coordinates.first else { return .automatic }

        guard coordinates.count > 1 else {
            return .region(
                MKCoordinateRegion(center: first, latitudinalMeters: 800, longitudinalMeters: 800)
            )
        }

        let rect = coordinates.reduce(MKMapRect.null) { rect, coordinate in
            rect.union(MKMapRect(origin: MKMapPoint(coordinate), size: MKMapSize(width: 0, height: 0)))
        }

        // Pad both axes by the larger dimension, otherwise a nearly straight route ends up
        // with almost no margin on its narrow side.
        let padding = max(rect.width, rect.height) * 0.25

        return .rect(rect.insetBy(dx: -padding, dy: -padding))
    }
}

#Preview("Ridge Hike") {
    RouteMapView(track: .mockRidgeHike)
}

#Preview("Costal Run") {
    RouteMapView(track: .mockCoastalRun)
}

#Preview("Empty") {
    RouteMapView(track: .mockEmpty)
}
