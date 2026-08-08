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
                    MapPolyline(coordinates: track.coordinates)
                        .stroke(.red.opacity(0.7), style: StrokeStyle(lineWidth: lineWidth + 5, lineCap: .round, lineJoin: .round))
                    
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
            
        }
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
