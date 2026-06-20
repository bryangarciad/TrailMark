//
//  MemoDetailView.swift
//  TrailMark (iOS)
//
//  Course 1.2 — plays a memo back. Video uses AVKit's VideoPlayer; audio uses
//  the shared TrailmarkCore.AudioPlayer. Shows the capture location if geotagged
//  (Course 1.4).
//

import SwiftUI
import AVKit
import MapKit
import TrailmarkCore

struct MemoDetailView: View {
    @Environment(AppModel.self) private var model
    let memo: MediaMemo

    @State private var audioPlayer = AudioPlayer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch memo.kind {
                case .video:
                    VideoPlayer(player: AVPlayer(url: model.media.url(for: memo)))
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .audio:
                    audioControls
                }

                metadata

                if let coordinate = memo.coordinate {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))) {
                        Marker(memo.title, coordinate: coordinate)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)
                }
            }
            .padding()
        }
        .navigationTitle(memo.kind.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { audioPlayer.stop() }
    }

    private var audioControls: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 80))
                .foregroundStyle(.teal)
                .symbolEffect(.variableColor, isActive: audioPlayer.isPlaying)
            Button {
                audioPlayer.isPlaying ? audioPlayer.stop() : audioPlayer.play(url: model.media.url(for: memo))
            } label: {
                Label(audioPlayer.isPlaying ? "Stop" : "Play",
                      systemImage: audioPlayer.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Recorded", value: memo.createdAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Duration", value: memo.durationText)
            if memo.coordinate != nil {
                LabeledContent("Location", value: "Geotagged")
            }
        }
        .font(.subheadline)
    }
}
