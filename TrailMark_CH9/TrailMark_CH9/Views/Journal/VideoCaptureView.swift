import SwiftUI
import AVFoundation
import UIKit
import UniformTypeIdentifiers

// Wraps UIImagePickerController for short video capture. On a device that's the
// camera; the Simulator has none, so it falls back to the photo library and the
// flow is still demonstrable.
struct VideoCaptureView: UIViewControllerRepresentable {
    /// Called with the captured file URL and its duration in seconds.
    let onCapture: (URL, TimeInterval) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
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

    @MainActor
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (URL, TimeInterval) -> Void

        init(onCapture: @escaping (URL, TimeInterval) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            guard let url = info[.mediaURL] as? URL else { return }
            // Reading the duration is async on modern AVFoundation, so the memo is
            // handed over once the load lands rather than inline.
            let asset = AVURLAsset(url: url)
            Task {
                let seconds = (try? await asset.load(.duration)).map(CMTimeGetSeconds) ?? 0
                onCapture(url, seconds.isFinite ? seconds : 0)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
