//
//  AudioPlayer.swift
//  TrailmarkCore
//
//  Course 1.2 / 2.2 — plays a recorded voice memo back. Shared by phone + wrist.
//

import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
public final class AudioPlayer: NSObject {

    public private(set) var isPlaying = false

    private var player: AVAudioPlayer?

    public override init() { super.init() }

    public func play(url: URL) {
        do {
            #if !os(macOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.play()
            self.player = player
            self.isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    public func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isPlaying = false }
    }
}
