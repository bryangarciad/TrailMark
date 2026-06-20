//
//  FieldJournalView.swift
//  TrailMark (iOS)
//
//  Course 1.2 — the field journal. Record voice + video memos, save them with
//  metadata into the shared MediaStore, list them with thumbnails + duration,
//  and open a detail view to play them back. Deleting removes the file too.
//
//  Memos are geotagged with the current location when captured (Course 1.4).
//

import SwiftUI
import TrailmarkCore

struct FieldJournalView: View {
    @Environment(AppModel.self) private var model

    @State private var showingAudioRecorder = false
    @State private var showingVideoPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if model.media.memos.isEmpty {
                    ContentUnavailableView("No memos yet",
                                           systemImage: "waveform",
                                           description: Text("Record a voice or video memo to start your field journal."))
                } else {
                    List {
                        ForEach(model.media.memos) { memo in
                            NavigationLink(value: memo) {
                                MemoRow(memo: memo)
                            }
                        }
                        .onDelete { model.media.delete(at: $0) }
                    }
                }
            }
            .navigationTitle("Field Journal")
            .navigationDestination(for: MediaMemo.self) { memo in
                MemoDetailView(memo: memo)
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { showingVideoPicker = true } label: {
                        Image(systemName: "video.badge.plus")
                    }
                    Button { showingAudioRecorder = true } label: {
                        Image(systemName: "mic.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAudioRecorder) {
                RecordAudioView()
            }
            .sheet(isPresented: $showingVideoPicker) {
                VideoCaptureView { url, duration in
                    saveVideo(url: url, duration: duration)
                }
                .ignoresSafeArea()
            }
            .onAppear { model.location.requestOneShotLocation() }
        }
    }

    private func saveVideo(url: URL, duration: TimeInterval) {
        try? model.media.add(kind: .video,
                             movingFileFrom: url,
                             duration: duration,
                             coordinate: model.location.currentCoordinate)
    }
}

/// One row: thumbnail (video) or waveform icon (audio), title, duration.
struct MemoRow: View {
    @Environment(AppModel.self) private var model
    let memo: MediaMemo
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.background.secondary)
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: memo.kind.symbolName)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title).font(.headline).lineLimit(1)
                HStack(spacing: 8) {
                    Label(memo.durationText, systemImage: "clock")
                    if memo.coordinate != nil {
                        Image(systemName: "mappin.circle.fill").foregroundStyle(.teal)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .task(id: memo.id) {
            thumbnail = await model.media.thumbnail(for: memo)
        }
    }
}

#Preview {
    FieldJournalView()
        .environment(AppModel())
}
