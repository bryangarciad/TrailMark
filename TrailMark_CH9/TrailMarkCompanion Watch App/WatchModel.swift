import Foundation
import Observation
import WidgetKit
import TrailMarkCore

// Owns the shared TrailMarkCore managers on the wrist. The whole point: the watch
// REUSES the same managers as the phone — no duplicated model or HealthKit code.
@MainActor
@Observable
final class WatchModel {
    let health = HealthKitManager()
    let media = MediaStore()
    let motion = MotionManager()
    let workout = WorkoutSessionManager()
    let connectivity = ConnectivityManager.shared

    init() {
        // When a live workout finishes, send the result over to the phone.
        workout.onFinish = { [weak self] record in
            self?.connectivity.sync(workout: record)
        }
        connectivity.activate()
    }

    /// Publishes today's step count into the App Group the complication reads.
    /// No-op until the App Group is configured (see the setup guide).
    func publishStepsToComplication() {
        let steps = Int(health.todaySummary.steps)
        UserDefaults(suiteName: "group.ramsesg.TrailMark")?.set(steps, forKey: "today.steps")
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Saves a just-recorded memo locally, then transfers the file to the phone so it
    /// shows up in the iOS journal ("pocket sync").
    func saveAndSync(memoFrom url: URL, duration: TimeInterval) {
        guard let memo = try? media.add(kind: .audio, movingFileFrom: url, duration: duration) else { return }
        connectivity.transfer(memo: memo, fileURL: media.url(for: memo))
    }
}
