//
//  VideoCaptureView.swift
//  TrailMark (iOS)
//
//  Course 1.2 — wraps UIImagePickerController for short video capture. Uses the
//  camera on a device; on the Simulator (no camera) it falls back to the photo
//  library so the flow is still demonstrable.
//

import SwiftUI
import AVFoundation
import UIKit
import UniformTypeIdentifiers

struct VideoCaptureView: UIViewControllerRepresentable {
    /// Called with the captured file URL and its duration in seconds.
    let onCapture: (URL, TimeInterval) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        // The Simulator has no camera; fall back to the library there.
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        if picker.sourceType == .camera {
            picker.cameraCaptureMode = .video
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (URL, TimeInterval) -> Void

        init(onCapture: @escaping (URL, TimeInterval) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            guard let url = info[.mediaURL] as? URL else { return }
            let duration = CMTimeGetSeconds(AVURLAsset(url: url).duration)
            onCapture(url, duration.isFinite ? duration : 0)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
