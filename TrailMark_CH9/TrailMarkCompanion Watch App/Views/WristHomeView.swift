import SwiftUI
import TrailMarkCore

struct WristHomeView: View {
    @Environment(WatchModel.self) private var model

    /// Prefer the summary the phone mirrored over; fall back to the watch's own read.
    private var summary: ActivitySummary {
        model.connectivity.mirroredSummary ?? model.health.todaySummary
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 2) {
                Text("Steps Today")
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
