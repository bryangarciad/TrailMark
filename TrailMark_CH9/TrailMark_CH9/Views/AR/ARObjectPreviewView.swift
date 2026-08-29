//
//  ARObjectPreviewView.swift
//  TrailMark_CH9 (iOS)
//
//  A standalone "see it in your space" screen: one 3D object, anchored to a real
//  horizontal surface through the rear camera, sized in real metres so you can judge
//  how big the thing actually is before you buy it or carry it up a hill.
//
//  Isolated on purpose — it reads no app state and writes none back, so it can be
//  pushed from anywhere (or previewed on its own) without touching the rest of the app.
//  It lands on the first surface ARKit finds; drag to spin, pinch to resize.
//
//  Needs a real device: ARKit world tracking does not exist on the Simulator.
//

import SwiftUI
import RealityKit
import ARKit
import AVFoundation
import Observation

@MainActor
struct ARObjectPreviewView: View {

    /// What to stand on the floor.
    enum Subject: Hashable {
        /// A `.usdz` in the app bundle, named without its extension.
        case bundled(name: String)
        /// Built from primitives, so this screen works with no assets checked in.
        case trailMarker
    }

    var subject: Subject = .trailMarker

    /// Forces the model to this height, uniformly. Leave it nil to trust the units baked
    /// into the file — a `.usdz` authored in metres already arrives at life size.
    var trueHeight: Measurement<UnitLength>? = nil

    @State private var stage = Stage()
    @State private var cameraAccess: CameraAccess = .pending

    // Gesture state lives here rather than on the entity, so the transform is always
    // recomputed from a single source of truth. `committed*` is the value at touch-down.
    @State private var yaw: Float = 0
    @State private var committedYaw: Float = 0
    @State private var scale: Float = 1
    @State private var committedScale: Float = 1

    var body: some View {
        Group {
            if !ARWorldTrackingConfiguration.isSupported {
                ContentUnavailableView(
                    "AR Needs a Real Device",
                    systemImage: "arkit",
                    description: Text("World tracking isn't available here. Run TrailMark on an iPhone or iPad to stand the object in your room.")
                )
            } else {
                switch cameraAccess {
                case .allowed:
                    scene
                case .pending:
                    ProgressView()
                case .denied:
                    ContentUnavailableView(
                        "Camera Is Off",
                        systemImage: "video.slash",
                        description: Text("Allow camera access in Settings › TrailMark to see the object in your space.")
                    )
                }
            }
        }
        .task { await resolveCameraAccess() }
    }

    // MARK: - AR scene

    private var scene: some View {
        RealityView { content in
            // The one line that turns a 3D view into an AR view: pass-through camera,
            // driven by the device's tracked pose.
            content.camera = .spatialTracking
            content.entities.append(stage.anchor)
            await stage.load(subject, trueHeight: trueHeight)
        } update: { _ in
            // Gestures are SwiftUI state; this is where that state reaches RealityKit.
            stage.pivot.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
            stage.pivot.scale = SIMD3(repeating: scale)
        }
        .ignoresSafeArea()
        .gesture(spin)
        .simultaneousGesture(resize)
        .overlay(alignment: .top) { coaching }
        .overlay(alignment: .bottom) { panel }
        .task {
            await stage.startTracking()
            await stage.followAnchorState()
        }
    }

    // MARK: - Gestures

    /// One finger spins the object about its own vertical axis — the "show me the back" motion.
    private var spin: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                yaw = committedYaw + Float(value.translation.width) * 0.01
            }
            .onEnded { _ in committedYaw = yaw }
    }

    /// Pinching breaks life size on purpose: sometimes you want to see the shape, not the size.
    /// The readout below keeps saying what scale you're at.
    private var resize: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                scale = min(max(committedScale * Float(value.magnification), 0.25), 4)
            }
            .onEnded { _ in committedScale = scale }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var coaching: some View {
        if !stage.isAnchored {
            Label("Aim at the floor and move slowly", systemImage: "viewfinder")
                .font(.callout)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(.regularMaterial, in: .capsule)
                .padding(.top, 8)
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let size = stage.modelSize {
                Text(sizeText(size))
                    .font(.callout.weight(.medium))
                    .monospacedDigit()
            }

            HStack {
                Text(scaleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Button("Reset", systemImage: "arrow.counterclockwise") {
                    yaw = 0
                    committedYaw = 0
                    scale = 1
                    committedScale = 1
                }
                .font(.caption)
                .disabled(yaw == 0 && scale == 1)
            }

            Text("Drag to spin · Pinch to resize")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .padding()
    }

    private var scaleText: String {
        scale == 1 ? "Life size" : "\(Int((scale * 100).rounded()))% of life size"
    }

    /// The whole point of the screen is answering "how big is it", so spell the object's
    /// footprint out in whatever units the user's locale prefers.
    private func sizeText(_ extents: SIMD3<Float>) -> String {
        let scaled = extents * scale
        let text = [scaled.x, scaled.y, scaled.z].map { value in
            Measurement(value: Double(value), unit: UnitLength.meters)
                .formatted(.measurement(width: .abbreviated, usage: .general))
        }
        return "\(text[0]) wide · \(text[1]) tall · \(text[2]) deep"
    }

    // MARK: - Camera permission

    private enum CameraAccess { case pending, allowed, denied }

    private func resolveCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAccess = .allowed
        case .notDetermined:
            cameraAccess = await AVCaptureDevice.requestAccess(for: .video) ? .allowed : .denied
        default:
            cameraAccess = .denied
        }
    }

    // MARK: - RealityKit side

    /// `RealityView` only hands us its content inside closures, but the entities have to
    /// outlive them — so they live on a reference type held in `@State`.
    /// `fileprivate`, not `private`: `@Observable` writes a conformance in an extension, and an
    /// extension can't reach a nested type that's private to its parent.
    @MainActor
    @Observable
    fileprivate final class Stage {

        /// `.once` so the object stays where it first landed instead of hopping to whichever
        /// plane ARKit prefers a moment later.
        let anchor = AnchorEntity(
            .plane(.horizontal, classification: .any, minimumBounds: [0.15, 0.15]),
            trackingMode: .once
        )

        /// Gestures drive this wrapper, not the model itself, so reloading the model can't
        /// throw away the framing the user chose.
        let pivot = Entity()

        private(set) var isAnchored = false

        /// Metres, at scale 1.
        private(set) var modelSize: SIMD3<Float>?

        private let session = SpatialTrackingSession()

        init() {
            anchor.addChild(pivot)
        }

        func load(_ subject: Subject, trueHeight: Measurement<UnitLength>?) async {
            let model: Entity

            switch subject {
            case .trailMarker:
                model = Self.trailMarker()
            case .bundled(let name):
                guard let loaded = try? await Entity(named: name) else { return }
                model = loaded
            }

            pivot.children.removeAll()
            pivot.addChild(model)

            // A .usdz can be authored in any unit, so normalising the height is the only way
            // to promise life size for a file we didn't make ourselves.
            if let target = trueHeight?.converted(to: .meters).value {
                let measured = model.visualBounds(relativeTo: pivot).extents.y
                if measured > 0 { model.scale *= Float(target) / measured }
            }

            // Centre it over the anchor and sit it *on* the plane, not half-buried in it.
            let bounds = model.visualBounds(relativeTo: pivot)
            model.position.x -= bounds.center.x
            model.position.y -= bounds.min.y
            model.position.z -= bounds.center.z

            let size = model.visualBounds(relativeTo: pivot).extents
            modelSize = size

            // SwiftUI gestures only reach entities that are hit-testable, which takes both
            // components: something to hit, and permission to be targeted.
            pivot.components.set(InputTargetComponent())
            pivot.components.set(
                CollisionComponent(shapes: [
                    .generateBox(size: size).offsetBy(translation: [0, size.y / 2, 0])
                ])
            )
        }

        /// The pass-through camera alone only gives us device pose; plane anchors have to be
        /// asked for explicitly.
        func startTracking() async {
            _ = await session.run(.init(tracking: [.plane]))
        }

        /// `AnchorEntity` exposes no stream for this, and a third of a second is plenty of
        /// resolution for a "keep moving" hint.
        func followAnchorState() async {
            while !Task.isCancelled {
                isAnchored = anchor.isAnchored
                if isAnchored { return }
                try? await Task.sleep(for: .milliseconds(300))
            }
        }

        /// A wooden trail signpost at roughly the size of the real ones: 1.2 m to the collar,
        /// with a blade you can read from walking distance. Stands in for a real asset so the
        /// screen is demonstrable with nothing checked into the repo.
        private static func trailMarker() -> Entity {
            let marker = Entity()
            let postHeight: Float = 1.2

            let post = ModelEntity(
                mesh: .generateCylinder(height: postHeight, radius: 0.04),
                materials: [SimpleMaterial(color: .brown, roughness: 0.9, isMetallic: false)]
            )
            post.position.y = postHeight / 2
            marker.addChild(post)

            let blade = ModelEntity(
                mesh: .generateBox(width: 0.44, height: 0.16, depth: 0.03, cornerRadius: 0.01),
                materials: [SimpleMaterial(color: .systemTeal, roughness: 0.4, isMetallic: false)]
            )
            blade.position = [0.14, postHeight - 0.18, 0.03]
            marker.addChild(blade)

            let cap = ModelEntity(
                mesh: .generateCone(height: 0.09, radius: 0.055),
                materials: [SimpleMaterial(color: .darkGray, roughness: 0.3, isMetallic: true)]
            )
            cap.position.y = postHeight + 0.045
            marker.addChild(cap)

            return marker
        }
    }
}

// The canvas has no camera or world tracking, so this preview renders the
// "needs a real device" state — which is exactly what you'd see on the Simulator.
#Preview {
    ARObjectPreviewView()
}
