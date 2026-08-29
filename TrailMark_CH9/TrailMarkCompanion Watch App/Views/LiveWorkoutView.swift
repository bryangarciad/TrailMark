import SwiftUI
import TrailMarkCore

// A live workout session. Starts an HKWorkoutSession on the watch, keeps streaming
// heart rate / elapsed time / energy while backgrounded, and saves a real HKWorkout
// on finish (which then syncs to the phone).
//
// The session logic itself lives in TrailMarkCore.WorkoutSessionManager.
struct LiveWorkoutView: View {
    @Environment(WatchModel.self) private var model
    @State private var elapsedText = "00:00"

    var body: some View {
        VStack(spacing: 12) {
            metric(
                model.workout.heartRate > 0 ? "\(Int(model.workout.heartRate))" : "--",
                unit: "bpm", symbol: "heart.fill", tint: .red
            )

            HStack {
                metric("\(Int(model.workout.activeEnergyKcal))", unit: "kcal",
                       symbol: "flame.fill", tint: .pink)
                metric(elapsedText, unit: "", symbol: "stopwatch", tint: .yellow)
            }

            Spacer()

            Button {
                model.workout.isWorkoutInProgress ? model.workout.end() : model.workout.start()
            } label: {
                Text(model.workout.isWorkoutInProgress ? "End" : "Start")
                    .frame(maxWidth: .infinity)
            }
            .tint(model.workout.isWorkoutInProgress ? .red : .green)
        }
        .padding(.horizontal, 4)
        .navigationTitle("Walk")
        .task {
            await model.health.requestAuthorization()
        }
        // Tick the elapsed readout once a second while the session runs.
        .task(id: model.workout.isWorkoutInProgress) {
            while model.workout.isWorkoutInProgress && !Task.isCancelled {
                let seconds = Int(model.workout.elapsed)
                elapsedText = String(format: "%02d:%02d", seconds / 60, seconds % 60)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func metric(_ value: String, unit: String, symbol: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol).foregroundStyle(tint)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .contentTransition(.numericText())
            if !unit.isEmpty {
                Text(unit).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
