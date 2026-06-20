//
//  RecoveryView.swift
//  TrailMark (iOS)
//
//  Course 1.3 — two-way HealthKit. Saves a sample activity as an HKWorkout
//  (verify it in the Health app), reads last night's sleep, and charts the last
//  7 days of active energy with Swift Charts. All queries live in TrailmarkCore.
//

import SwiftUI
import Charts
import TrailmarkCore

struct RecoveryView: View {
    @Environment(AppModel.self) private var model
    @State private var saveState: SaveState = .idle

    enum SaveState: Equatable { case idle, saving, saved, failed(String) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    sleepCard
                    energyChartCard
                    saveWorkoutCard
                }
                .padding()
            }
            .navigationTitle("Recovery")
            .task {
                await model.health.refreshLastNightSleep()
                await model.health.refreshEnergyTrend()
            }
            .refreshable {
                await model.health.refreshLastNightSleep()
                await model.health.refreshEnergyTrend()
            }
        }
    }

    private var sleepCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Last night's sleep", systemImage: "bed.double.fill")
                .font(.headline)
            Text(model.health.sleep.asleepSeconds > 0 ? model.health.sleep.durationText : "No sleep data")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.indigo)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var energyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active energy · last 7 days", systemImage: "flame.fill")
                .font(.headline)
            if model.health.energyTrend.isEmpty {
                Text("No energy data yet.").foregroundStyle(.secondary)
            } else {
                Chart(model.health.energyTrend) { point in
                    BarMark(
                        x: .value("Day", point.day, unit: .day),
                        y: .value("kcal", point.activeEnergyKcal)
                    )
                    .foregroundStyle(.red.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var saveWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Log a sample workout", systemImage: "figure.walk")
                .font(.headline)
            Text("Saves a 30-minute walk to HealthKit so you can confirm it appears in the Health app.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button(action: saveSampleWorkout) {
                HStack {
                    if saveState == .saving { ProgressView().padding(.trailing, 4) }
                    Text(buttonTitle)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(saveState == .saving)

            if case .failed(let message) = saveState {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var buttonTitle: String {
        switch saveState {
        case .saved: return "Saved ✓ — check the Health app"
        default: return "Save sample workout"
        }
    }

    private func saveSampleWorkout() {
        saveState = .saving
        let end = Date()
        let record = WorkoutRecord(start: end.addingTimeInterval(-1800),
                                   end: end,
                                   activeEnergyKcal: 180,
                                   distanceMeters: 2400)
        Task {
            do {
                try await model.health.save(record)
                saveState = .saved
                await model.health.refreshEnergyTrend()
            } catch {
                saveState = .failed(error.localizedDescription)
            }
        }
    }
}

#Preview {
    RecoveryView()
        .environment(AppModel())
}
