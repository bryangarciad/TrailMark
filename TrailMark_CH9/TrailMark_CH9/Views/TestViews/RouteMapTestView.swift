import SwiftUI
import TrailMarkCore

struct RouteMapTestView: View {
    
    private struct Sample: Identifiable {
        let id = UUID()
        let name: String
        let track: RouteTrack
    }
    
    private let samples: [Sample] = [
        Sample(name: "Park Loop", track: .mockParkLoop),
        Sample(name: "Ridge Hike", track: .mockRidgeHike),
        Sample(name: "Costal Run", track: .mockCoastalRun),
        Sample(name: "Just Started (Not Finished)", track: .mockJustStarted),
        Sample(name: "Empty", track: .mockEmpty)
    ]
    
    @State private var selectedIndex = 0
    @State private var showEndpoints = true
    
    private var selected: Sample { samples[selectedIndex] }
    
    var body: some View {
        NavigationStack {
            // Any UI To display the selector
            // RouteMapView()
            RouteMapView(track: selected.track, showsEndpointsshowsEndpoints: showEndpoints)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .bottom) { statsCard }
                .navigationTitle(selected.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Picker("Track", selections: $selectedIndex) {
                            ForEach(samples.indices, id: ./self) {
                                Text(samples[index].name).tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Toggle(isOn: $showEndpoints) {
                            Label("Endpoints", systemImage: "Flag")
                        }
                        .toggleStyle(.button)
                        .labelStyle(.iconOnly)
                    }
                }
        }
    }
    
    private var statsCard: some View {
        let track = selected.track
        
        return HStack(alignment: .top, padding: 16) {
            stat("Points", "\(track.points.count)")
            stat("Distance", "\(distanceText(track))")
            stat("Duration", "\(durationText(track))")
            stat("Gain", "\(gainText(track))")
        }
    }
    
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.medium))
                .monospacedDigit()
        }
        .frame(maxWidth: infinity, alignment: .leading)
    }
    
    private func distanceText(_ track: RouteTrack) -> String {
        Measurement(value: track.distanceMeters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }
    
    private func durationText(_ track: RouteTrack) -> String {
        guard let start = track.points.first?.timestamp,
              let end = track.points.last?.timestamp,
              end > start
        else { return "-" }
        
        return Duration.seconds(end.timeIntervalSince(start)).formatted(.time(pattern: .minuteSecond))
    }
    
    private func gainText(_ track: RouteTrack) -> String {
        return Measurement(value: track.altitudeGain, unit: UnitLength.meters)
                .formatted(.measurement(width: .abbreviated, usage: .asProvided))
    }
}

#Preview {
    RouteMapTestView()
}
