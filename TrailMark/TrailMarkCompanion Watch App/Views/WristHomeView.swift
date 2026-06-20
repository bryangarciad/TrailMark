//
//  WristHomeView.swift
//  TrailMarkCompanion Watch App
//
//  Course 2.1 — the glanceable home. One headline metric (today's steps) and
//  the data is readable in about two seconds. Design choice: a single large,
//  high-contrast number rather than a dashboard of tiles — watchOS guidelines
//  favour one focused, glanceable piece of information over dense layouts.
//
//  Prefers the summary mirrored from the phone (Course 3.1) when present, and
//  falls back to the watch's own HealthKit read otherwise.
//

import SwiftUI
import TrailmarkCore

struct WristHomeView: View {
    @Environment(WatchModel.self) private var model

    private var summary: ActivitySummary {
        model.connectivity.mirroredSummary ?? model.health.todaySummary
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 2) {
                Text("Steps today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(summary.stepsText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())
                Text(summary.distanceText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(Color.clear)
        }
    }
}
