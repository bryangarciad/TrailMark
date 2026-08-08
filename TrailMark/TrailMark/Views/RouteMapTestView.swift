//
//  RouteMapTestView.swift
//  TrailMark_CH9
//
//  Scratch harness: flip between the mock tracks and check how each one renders.
//  Not part of the real UI — delete it once the actual journey screens exist.
//

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
        Sample(name: "Coastal Run", track: .mockCoastalRun),
        Sample(name: "Just Started", track: .mockJustStarted),
        Sample(name: "Empty", track: .mockEmpty)
    ]

    @State private var selectedIndex = 0
    @State private var showsEndpoints = true

    private var selected: Sample { samples[selectedIndex] }

    var body: some View {
        NavigationStack {
            RouteMapView(track: selected.track, showsEndpoints: showsEndpoints)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .bottom) { statsCard }
                .navigationTitle(selected.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Picker("Track", selection: $selectedIndex) {
                            ForEach(samples.indices, id: \.self) { index in
                                Text(samples[index].name).tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Toggle(isOn: $showsEndpoints) {
                            Label("Endpoints", systemImage: "flag")
                        }
                        .toggleStyle(.button)
                        .labelStyle(.iconOnly)
                    }
                }
        }
    }

    // MARK: - Stats

    private var statsCard: some View {
        let track = selected.track

        return HStack(alignment: .top, spacing: 16) {
            stat("Points", "\(track.points.count)")
            stat("Distance", distanceText(track))
            stat("Duration", durationText(track))
            stat("Gain", gainText(track))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .padding()
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func distanceText(_ track: RouteTrack) -> String {
        Measurement(value: track.distanceMeters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }

    private func durationText(_ track: RouteTrack) -> String {
        guard let start = track.points.first?.timestamp,
              let end = track.points.last?.timestamp,
              end > start
        else { return "—" }

        return Duration.seconds(end.timeIntervalSince(start))
            .formatted(.time(pattern: .minuteSecond))
    }

    /// Total climbing only — descents don't count toward gain.
    private func gainText(_ track: RouteTrack) -> String {
        guard track.points.count > 1 else { return "—" }

        var gain: Double = 0
        for index in 1..<track.points.count {
            let delta = track.points[index].altitude - track.points[index - 1].altitude
            if delta > 0 { gain += delta }
        }

        return Measurement(value: gain, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided))
    }
}

#Preview {
    RouteMapTestView()
}
