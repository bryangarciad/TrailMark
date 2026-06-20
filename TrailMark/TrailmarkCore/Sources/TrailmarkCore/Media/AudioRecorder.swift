//
//  AudioRecorder.swift
//  TrailmarkCore
//
//  Course 1.2 / 2.2 — voice-memo recording with AVAudioRecorder. Shared by the
//  phone and the wrist; only the audio-session category setup differs, handled
//  here so callers don't have to think about it.
//

import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
public final class AudioRecorder {

    public private(set) var isRecording = false
    public private(set) var elapsed: TimeInterval = 0
    /// Set after `stop()` — the temp file you hand to `MediaStore.add`.
    public private(set) var lastRecordingURL: URL?

    private var recorder: AVAudioRecorder?
    private var startDate: Date?

    public init() {}

    /// Configures the audio session and begins recording to a temp .m4a file.
    public func start() throws {
        try configureSession()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.record()
        self.recorder = recorder
        self.startDate = Date()
        self.isRecording = true
        self.elapsed = 0
    }

    /// Stops recording and returns the file URL + measured duration.
    @discardableResult
    public func stop() -> (url: URL, duration: TimeInterval)? {
        guard let recorder else { return nil }
        let duration = startDate.map { Date().timeIntervalSince($0) } ?? recorder.currentTime
        recorder.stop()
        let url = recorder.url
        self.recorder = nil
        self.isRecording = false
        self.lastRecordingURL = url
        self.elapsed = duration
        deactivateSession()
        return (url, duration)
    }

    /// Call from a timer/TimelineView tick to refresh the elapsed readout.
    public func tick() {
        guard isRecording, let startDate else { return }
        elapsed = Date().timeIntervalSince(startDate)
    }

    private func configureSession() throws {
        #if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.duckOthers])
        try session.setActive(true)
        #endif
    }

    private func deactivateSession() {
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        #endif
    }
}
