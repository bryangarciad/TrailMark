import SwiftUI
import TrailMarkCore

// Live vitals on the wrist. Once authorized it shows current heart rate, steps and
// active energy, updating as samples arrive. Reuses the shared TrailMarkCore
// HealthKit manager — no new HealthKit code on the watch.
struct LiveVitalsView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        List {
            vital(
                title: "Heart rate",
                value: model.health.liveVital.heartRateText,
                unit: "bpm",
                symbol: "heart.fill",
                tint: .red
            )
            vital(
                title: "Steps",
                value: "\(Int(model.health.liveVital.steps))",
                unit: "",
                symbol: "figure.walk",
                tint: .orange
            )
            vital(
                title: "Active energy",
                value: "\(Int(model.health.liveVital.activeEnergyKcal))",
                unit: "kcal",
                symbol: "flame.fill",
                tint: .pink
            )
        }
        .navigationTitle("Live Vitals")
        .task {
            await model.health.requestAuthorization()
            model.health.startLiveVitals()
        }
        .onDisappear { model.health.stopLiveVitals() }
    }

    private func vital(title: String, value: String, unit: String, symbol: String, tint: Color) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(tint)
            VStack(alignment: .leading) {
                Text(title).font(.caption2).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .contentTransition(.numericText())
                    if !unit.isEmpty {
                        Text(unit).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
