//
//  WristMemoView.swift
//  TrailMarkCompanion Watch App
//
//  Course 2.2 — voice memos on the wrist. Records via the shared AudioRecorder,
//  saves via the shared MediaStore, lists saved memos and plays one back. The
//  interface is pared down to the essentials a wrist actually needs, and each
//  saved memo is transferred to the phone (Course 3.1).
//

import SwiftUI
import TrailmarkCore

struct WristMemoView: View {
    @Environment(WatchModel.self) private var model
    @State private var recorder = AudioRecorder()
    @State private var player = AudioPlayer()

    var body: some View {
        List {
            Section {
                Button {
                    recorder.isRecording ? finish() : begin()
                } label: {
                    Label(recorder.isRecording ? "Stop · \(elapsed)" : "Record",
                          systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .foregroundStyle(recorder.isRecording ? .red : .accentColor)
                }
            }

            Section("Memos") {
                if model.media.memos.isEmpty {
                    Text("No memos yet").foregroundStyle(.secondary)
                } else {
                    ForEach(model.media.memos) { memo in
                        Button {
                            player.play(url: model.media.url(for: memo))
                        } label: {
                            HStack {
                                Image(systemName: "play.circle")
                                VStack(alignment: .leading) {
                                    Text(memo.title).font(.caption).lineLimit(1)
                                    Text(memo.durationText).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { model.media.delete(at: $0) }
                }
            }
        }
        .navigationTitle("Voice Memo")
        .task(id: recorder.isRecording) {
            while recorder.isRecording && !Task.isCancelled {
                recorder.tick()
                try? await Task.sleep(for: .seconds(0.2))
            }
        }
    }

    private var elapsed: String {
        let s = Int(recorder.elapsed)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func begin() {
        try? recorder.start()
    }

    private func finish() {
        guard let result = recorder.stop() else { return }
        model.saveAndSync(memoFrom: result.url, duration: result.duration)
    }
}
