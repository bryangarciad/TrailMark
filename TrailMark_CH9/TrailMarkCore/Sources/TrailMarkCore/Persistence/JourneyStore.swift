import Foundation
import Observation

// Persists journeys to a JSON file in Application Support, and is the landing
// spot for journeys synced over from the watch.
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

    // MARK: - Mutating

    public func add(_ journey: Journey) {
        if let index = journeys.firstIndex(where: { $0.id == journey.id }) {
            journeys[index] = journey
        } else {
            journeys.insert(journey, at: 0)
        }
        journeys.sort { $0.startedAt > $1.startedAt } // newest first (DESC Ord)
        persist()
    }

    public func delete(_ journey: Journey) {
        journeys.removeAll { $0.id == journey.id }
        persist()
    }

    public func delete(at offsets: IndexSet) {
        offsets.map { journeys[$0] }.forEach(delete)
    }

    // MARK: - Persistance

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
