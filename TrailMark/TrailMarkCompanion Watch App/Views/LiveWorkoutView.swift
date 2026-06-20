//
//  LiveWorkoutView.swift
//  TrailMarkCompanion Watch App
//
//  Course 3.2 — a live workout session. Starts an HKWorkoutSession on the
//  watch, keeps streaming heart rate / elapsed time / energy while backgrounded,
//  and saves a real HKWorkout on finish (then syncs the result to the phone).
//
//  The session logic lives in TrailmarkCore.WorkoutSessionManager.
//

import SwiftUI
import TrailmarkCore

struct LiveWorkoutView: View {
    @Environment(WatchModel.self) private var model
    @State private var elapsedText = "00:00"

    var body: some View {
        VStack(spacing: 12) {
            metric(model.workout.heartRate > 0 ? "\(Int(model.workout.heartRate))" : "--",
                   unit: "bpm", symbol: "heart.fill", tint: .red)

            HStack {
                metric("\(Int(model.workout.activeEnergyKcal))", unit: "kcal",
                       symbol: "flame.fill", tint: .pink)
                metric(elapsedText, unit: "", symbol: "stopwatch", tint: .yellow)
            }

            Spacer()

            Button {
                model.workout.isRunning ? model.workout.end() : model.workout.start()
            } label: {
                Text(model.workout.isRunning ? "End" : "Start")
                    .frame(maxWidth: .infinity)
            }
            .tint(model.workout.isRunning ? .red : .green)
        }
        .padding(.horizontal, 4)
        .navigationTitle("Walk")
        .task {
            await model.health.requestAuthorization()
        }
        // Tick the elapsed-time readout once a second while running.
        .task(id: model.workout.isRunning) {
            while model.workout.isRunning && !Task.isCancelled {
                let s = Int(model.workout.elapsed)
                elapsedText = String(format: "%02d:%02d", s / 60, s % 60)
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
