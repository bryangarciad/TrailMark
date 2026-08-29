import Foundation
import AVFoundation
import CoreLocation
import Observation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

@MainActor
@Observable
public final class MediaStore {
    public private(set) var memos: [MediaMemo] = []
    
    private let fileManager = FileManager.default
    private let indexFileName = "memos.json"
    
    public init() {
        loadIndex()
    }
    
    public var mediaDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Media", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public var indexURL: URL {
        mediaDirectory.appendingPathComponent(indexFileName)
    }

    public func url(for memo: MediaMemo) -> URL {
        mediaDirectory.appendingPathComponent(memo.fileName)
    }
    
    // MARK: - Saving
    @discardableResult
    public func add(kind: MemoKind, movingFileFrom sourceURL: URL, duration: TimeInterval, title: String = "", coordinate: CLLocationCoordinate2D? = nil) throws -> MediaMemo {
        let id = UUID()
        let ext = sourceURL.pathExtension.isEmpty ? (kind == .audio ? "m4a" : "mov") : sourceURL.pathExtension
        let fileName = "\(id.uuidString).\(ext)"
        let destination = mediaDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        
        try fileManager.moveItem(at: sourceURL, to: destination)
        
        var memo = MediaMemo(
            id: id,
            kind: kind,
            fileName: fileName,
            duration: duration,
            title: title
        )
        
        memo.setCoordinate(coordinate)
        
        memos.insert(memo, at: 0)
        persistIndex()
        return memo
    }
    
    public func register(_ memo: MediaMemo) {
        guard !memos.contains(where: { $0.id == memo.id }) else { return }
        memos.insert(memo, at: 0)
        memos.sort { $0.createdAt > $1.createdAt }
        persistIndex()

    }

    /// Updates an existing memo's metadata (e.g. a geotag added after the fact).
    public func update(_ memo: MediaMemo) {
        guard let index = memos.firstIndex(where: { $0.id == memo.id }) else { return }
        memos[index] = memo
        persistIndex()
    }

    // MARK: - Deleting (also removes the file from disk)

    public func delete(_ memo: MediaMemo) {
        try? fileManager.removeItem(at: url(for: memo))
        memos.removeAll { $0.id == memo.id }
        persistIndex()
    }

    public func delete(at offsets: IndexSet) {
        offsets.map { memos[$0] }.forEach(delete)
    }

    // MARK: - Thumbnails

    #if canImport(UIKit) && !os(watchOS)
    /// Generates a thumbnail for a video memo, nil for audio. iOS only: the watch
    /// never captures video and AVAssetImageGenerator doesn't exist there.
    public func thumbnail(for memo: MediaMemo) async -> UIImage? {
        guard memo.kind == .video else { return nil }
        let asset = AVURLAsset(url: url(for: memo))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        do {
            return UIImage(cgImage: try await generator.image(at: time).image)
        } catch {
            return nil
        }
    }
    #endif

    // MARK: - index Persistance
    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        let decoded = (try? JSONDecoder.trailmark.decode([MediaMemo].self, from: data)) ?? []
        memos = decoded.sorted { $0.createdAt > $1.createdAt } // This reconstructs the media arr with newest first (DESC Ord)
    }

    private func persistIndex() {
        guard let data = try? JSONEncoder.trailmark.encode(memos) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
