//
//  RouteMapView.swift
//  TrailMark_CH9
//
//  Draws a RouteTrack as a line on a map, framed so the whole route fits.
//

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
                description: Text("Start a journey to see it drawn here.")
            )
        } else {
            Map(position: $camera) {
                if track.points.count > 1 {
                    // Casing underneath so the route stays readable over dark terrain.
                    MapPolyline(coordinates: track.coordinates)
                        .stroke(.white.opacity(0.7), style: strokeStyle(width: lineWidth + 3))

                    MapPolyline(coordinates: track.coordinates)
                        .stroke(.blue, style: strokeStyle(width: lineWidth))
                }

                if showsEndpoints {
                    if let start = track.points.first {
                        Annotation("Start", coordinate: start.coordinate) {
                            endpoint(color: .green, systemImage: "flag.fill")
                        }
                    }

                    if let end = track.points.last, track.points.count > 1 {
                        Annotation("Finish", coordinate: end.coordinate) {
                            endpoint(color: .red, systemImage: "flag.checkered")
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .task(id: track) {
                camera = Self.cameraPosition(for: track)
            }
        }
    }

    private func strokeStyle(width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    private func endpoint(color: Color, systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(6)
            .background(color, in: .circle)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(radius: 2, y: 1)
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

#Preview("Coastal Run") {
    RouteMapView(track: .mockCoastalRun)
}

#Preview("Empty") {
    RouteMapView(track: .mockEmpty)
}
