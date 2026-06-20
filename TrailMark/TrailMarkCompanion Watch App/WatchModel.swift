//
//  WatchModel.swift
//  TrailMarkCompanion Watch App
//
//  Owns the shared TrailmarkCore managers on the wrist. The whole point of the
//  curriculum: the watch REUSES the same managers as the phone — no duplicated
//  model or HealthKit code (Course 2.1).
//

import Foundation
import Observation
import WidgetKit
import TrailmarkCore

@MainActor
@Observable
final class WatchModel {
    let health = HealthKitManager()
    let media = MediaStore()
    let motion = MotionManager()
    let workout = WorkoutSessionManager()
    let connectivity = ConnectivityManager.shared

    init() {
        // When a live workout finishes, sync the result to the phone (Course 3.1).
        workout.onFinish = { [weak self] record in
            self?.connectivity.sync(workout: record)
        }
        connectivity.activate()
    }

    /// Publishes today's step count to the App Group the complication reads
    /// (Course 3.4). No-op until the App Group is configured (see MANUAL_SETUP).
    func publishStepsToComplication() {
        let steps = Int(health.todaySummary.steps)
        UserDefaults(suiteName: "group.ramsesg.TrailMark")?.set(steps, forKey: "today.steps")
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Saves a just-recorded memo locally, then transfers the file to the phone
    /// so it shows up in the iOS journal (Course 3.1 "Pocket sync").
    func saveAndSync(memoFrom url: URL, duration: TimeInterval) {
        guard let memo = try? media.add(kind: .audio, movingFileFrom: url, duration: duration) else { return }
        connectivity.transfer(memo: memo, fileURL: media.url(for: memo))
    }
}
