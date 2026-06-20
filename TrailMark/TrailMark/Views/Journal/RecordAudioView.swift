//
//  RecordAudioView.swift
//  TrailMark (iOS)
//
//  Course 1.2 — voice memo capture UI. Recording itself lives in
//  TrailmarkCore.AudioRecorder; this view is just the controls + a live timer.
//

import SwiftUI
import TrailmarkCore

struct RecordAudioView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var recorder = AudioRecorder()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Text(timeString(recorder.elapsed))
                    .font(.system(size: 56, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())

                Image(systemName: recorder.isRecording ? "waveform.circle.fill" : "mic.circle")
                    .font(.system(size: 96))
                    .foregroundStyle(recorder.isRecording ? .red : .secondary)
                    .symbolEffect(.pulse, isActive: recorder.isRecording)

                Spacer()

                Button {
                    recorder.isRecording ? finish() : begin()
                } label: {
                    Text(recorder.isRecording ? "Stop & Save" : "Start Recording")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(recorder.isRecording ? Color.red : Color.accentColor,
                                    in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }

                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("Voice Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // Drive the elapsed-time readout while recording.
            .task(id: recorder.isRecording) {
                while recorder.isRecording && !Task.isCancelled {
                    recorder.tick()
                    try? await Task.sleep(for: .seconds(0.1))
                }
            }
        }
    }

    private func begin() {
        do { try recorder.start() }
        catch { errorMessage = error.localizedDescription }
    }

    private func finish() {
        guard let result = recorder.stop() else { return }
        try? model.media.add(kind: .audio,
                             movingFileFrom: result.url,
                             duration: result.duration,
                             coordinate: model.location.currentCoordinate)
        dismiss()
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    RecordAudioView()
        .environment(AppModel())
}
