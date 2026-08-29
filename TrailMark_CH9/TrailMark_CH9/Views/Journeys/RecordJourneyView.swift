import SwiftUI
import MapKit
import TrailMarkCore

// Records a coordinate track through the shared LocationManager and saves it as a
// Journey, attaching any memos captured while the recording was running.
struct RecordJourneyView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var startedAt: Date?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Map {
                    if !model.location.track.isEmpty {
                        MapPolyline(coordinates: model.location.track.coordinates)
                            .stroke(.orange, lineWidth: 4)
                    }
                    UserAnnotation()
                }
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 4) {
                    Text(distanceText)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("\(model.location.track.points.count) points recorded")
                        .font(.caption).foregroundStyle(.secondary)
                }

                if !model.location.isTracking {
                    TextField("Journey title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    model.location.isTracking ? stop() : start()
                } label: {
                    Text(model.location.isTracking ? "Stop and Save" : "Start Recording")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            model.location.isTracking ? Color.red : Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .navigationTitle("New Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if model.location.isTracking { model.location.stopRecording() }
                        dismiss()
                    }
                }
            }
            .onAppear { model.location.requestWhenInUseAuthorization() }
        }
    }

    private var distanceText: String {
        Measurement(value: model.location.track.distanceMeters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }

    private func start() {
        startedAt = Date()
        model.location.startRecording()
    }

    private func stop() {
        let track = model.location.stopRecording()
        let start = startedAt ?? Date()
        let end = Date()

        // Attach any memos captured inside this journey's window.
        let memoIDs = model.media.memos
            .filter { $0.createdAt >= start && $0.createdAt <= end }
            .map(\.id)

        let journey = Journey(
            title: title.isEmpty ? "Journey" : title,
            startedAt: start,
            endedAt: end,
            track: track,
            memoIDs: memoIDs
        )
        model.journeys.add(journey)
        model.connectivity.sync(journey: journey)
        dismiss()
    }
}
