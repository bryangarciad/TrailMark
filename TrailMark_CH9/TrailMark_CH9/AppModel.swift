import Foundation
import Observation
import TrailMarkCore

// Owns the long-lived managers from TrailMarkCore and wires up cross-device sync.
// Injected into the SwiftUI environment so every screen shares one instance of each
// manager, and therefore one source of truth.
@MainActor
@Observable
final class AppModel {
    let health = HealthKitManager()
    let media = MediaStore()
    let location = LocationManager()
    let journeys = JourneyStore()
    let connectivity = ConnectivityManager.shared

    init() {
        wireConnectivity()
    }

    /// Files payloads synced over from the watch into the right store, so they show
    /// up in the iOS journey / journal lists.
    private func wireConnectivity() {
        connectivity.onReceiveJourney = { [weak self] journey in
            self?.journeys.add(journey)
        }
        connectivity.onReceiveWorkout = { [weak self] workout in
            // Wrap a bare workout in a minimal journey so it still surfaces in the list.
            let journey = Journey(
                title: "Watch activity",
                startedAt: workout.start,
                endedAt: workout.end,
                workout: workout
            )
            self?.journeys.add(journey)
        }
        connectivity.onReceiveMediaFile = { [weak self] tempURL, memo in
            guard let self else { return }
            // Move the received file into the media directory under the memo's name.
            let destination = self.media.mediaDirectory.appendingPathComponent(memo.fileName)
            try? FileManager.default.removeItem(at: destination)
            try? FileManager.default.moveItem(at: tempURL, to: destination)
            self.media.register(memo)
        }
        connectivity.activate()
    }

    /// Pushes today's summary to the watch as glanceable mirrored state.
    func mirrorTodayToWatch() {
        connectivity.sync(summary: health.todaySummary)
    }
}
