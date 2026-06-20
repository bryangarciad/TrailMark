//
//  JourneyDetailView.swift
//  TrailMark (iOS)
//
//  Course 1.4 — the unified "Journey detail" screen: route polyline + memo pins
//  on a map, the activity stats, and the captured media in one place. This is
//  where the three Course-1 builds come together.
//

import SwiftUI
import MapKit
import TrailmarkCore

struct JourneyDetailView: View {
    @Environment(AppModel.self) private var model
    let journey: Journey

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                map
                stats
                if let workout = journey.workout { workoutSection(workout) }
                memosSection
            }
            .padding()
        }
        .navigationTitle(journey.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var memos: [MediaMemo] {
        model.media.memos.filter { journey.memoIDs.contains($0.id) }
    }

    private var map: some View {
        Map(initialPosition: cameraPosition) {
            if !journey.track.isEmpty {
                MapPolyline(coordinates: journey.track.coordinates)
                    .stroke(.orange, lineWidth: 4)
            }
            ForEach(memos) { memo in
                if let coordinate = memo.coordinate {
                    Marker(memo.kind.displayName, systemImage: memo.kind.symbolName, coordinate: coordinate)
                }
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var cameraPosition: MapCameraPosition {
        if let first = journey.track.points.first {
            return .region(MKCoordinateRegion(center: first.coordinate,
                                              span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
        }
        return .automatic
    }

    private var stats: some View {
        HStack {
            stat("Distance", Measurement(value: journey.distanceMeters, unit: UnitLength.meters)
                .formatted(.measurement(width: .abbreviated, usage: .road)))
            Divider()
            stat("Memos", "\(journey.memoIDs.count)")
            Divider()
            stat("Date", journey.startedAt.formatted(date: .abbreviated, time: .omitted))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func workoutSection(_ workout: WorkoutRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Activity", systemImage: "figure.walk").font(.headline)
            LabeledContent("Duration", value: workout.durationText)
            LabeledContent("Active energy", value: "\(Int(workout.activeEnergyKcal)) kcal")
            if let hr = workout.averageHeartRate {
                LabeledContent("Avg heart rate", value: "\(Int(hr)) bpm")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var memosSection: some View {
        if !memos.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Captured along the way").font(.headline)
                ForEach(memos) { memo in
                    NavigationLink(value: memo) { MemoRow(memo: memo) }
                }
            }
        }
    }
}
