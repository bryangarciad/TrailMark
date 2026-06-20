//
//  JourneyStore.swift
//  TrailmarkCore
//
//  Course 1.4 / 3.1 — persists journeys and is the destination for journeys
//  synced from the watch. Backed by a JSON file in Application Support.
//

import Foundation
import Observation

@MainActor
@Observable
public final class JourneyStore {

    public private(set) var journeys: [Journey] = []

    private let fileManager = FileManager.default

    public init() {
        load()
    }

    private var fileURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("journeys.json")
    }

    public func add(_ journey: Journey) {
        if let index = journeys.firstIndex(where: { $0.id == journey.id }) {
            journeys[index] = journey
        } else {
            journeys.insert(journey, at: 0)
        }
        journeys.sort { $0.startedAt > $1.startedAt }
        persist()
    }

    public func delete(_ journey: Journey) {
        journeys.removeAll { $0.id == journey.id }
        persist()
    }

    public func delete(at offsets: IndexSet) {
        offsets.map { journeys[$0] }.forEach(delete)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoded = (try? JSONDecoder.trailmark.decode([Journey].self, from: data)) ?? []
        journeys = decoded.sorted { $0.startedAt > $1.startedAt }
    }

    private func persist() {
        guard let data = try? JSONEncoder.trailmark.encode(journeys) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
