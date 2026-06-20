//
//  AppModel.swift
//  TrailMark (iOS)
//
//  Owns the long-lived managers from TrailmarkCore and wires up cross-device
//  sync. Injected into the SwiftUI environment so every screen shares one
//  instance of each manager (and therefore one source of truth).
//

import Foundation
import Observation
import TrailmarkCore

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

    /// Receives payloads synced from the watch (Course 3.1) and files them into
    /// the right store so they appear in the iOS journey / journal lists.
    private func wireConnectivity() {
        connectivity.onReceiveJourney = { [weak self] journey in
            self?.journeys.add(journey)
        }
        connectivity.onReceiveWorkout = { [weak self] workout in
            // Wrap a bare workout in a minimal journey so it surfaces in the list.
            let journey = Journey(title: "Watch activity",
                                  startedAt: workout.start,
                                  endedAt: workout.end,
                                  workout: workout)
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
