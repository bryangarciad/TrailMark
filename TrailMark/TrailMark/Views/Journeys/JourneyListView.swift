//
//  JourneyListView.swift
//  TrailMark (iOS)
//
//  Course 1.4 — the journey list and the entry point to recording a new one.
//  A journey unites a route, health, and media into one record.
//

import SwiftUI
import TrailmarkCore

struct JourneyListView: View {
    @Environment(AppModel.self) private var model
    @State private var showingRecorder = false

    var body: some View {
        NavigationStack {
            Group {
                if model.journeys.journeys.isEmpty {
                    ContentUnavailableView("No journeys yet",
                                           systemImage: "map",
                                           description: Text("Record a journey to map where you went."))
                } else {
                    List {
                        ForEach(model.journeys.journeys) { journey in
                            NavigationLink(value: journey) {
                                JourneyRow(journey: journey)
                            }
                        }
                        .onDelete { model.journeys.delete(at: $0) }
                    }
                }
            }
            .navigationTitle("Journeys")
            .navigationDestination(for: Journey.self) { journey in
                JourneyDetailView(journey: journey)
            }
            .navigationDestination(for: MediaMemo.self) { memo in
                MemoDetailView(memo: memo)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingRecorder = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingRecorder) {
                RecordJourneyView()
            }
        }
    }
}

struct JourneyRow: View {
    let journey: Journey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(journey.title).font(.headline)
            HStack(spacing: 12) {
                Label(distanceText, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                Label("\(journey.memoIDs.count)", systemImage: "waveform")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text(journey.dateText).font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private var distanceText: String {
        let measurement = Measurement(value: journey.distanceMeters, unit: UnitLength.meters)
        return measurement.formatted(.measurement(width: .abbreviated, usage: .road))
    }
}

#Preview {
    JourneyListView()
        .environment(AppModel())
}
