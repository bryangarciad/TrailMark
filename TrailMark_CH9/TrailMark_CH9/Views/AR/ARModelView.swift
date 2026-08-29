//
//  ARModelView.swift
//  TrailMark_CH9 (iOS)
//
//  Pass-through camera, one USD model, placed by tapping where you want it. ARKit finds
//  the surface; the tap decides where on it the object stands. Tap again to move it.
//
//  Needs a real device — world tracking does not exist on the Simulator.
//

import SwiftUI
import RealityKit

@MainActor
struct ARModelView: View {

    /// Bundle resource name, without the extension: `TrailSign.usdc` → `"TrailSign"`.
    var modelName: String

    /// The object's height in real life, measured off the actual thing. The model is scaled
    /// uniformly to match, which sidesteps USD units completely: it lands at true size whether
    /// the file was authored in metres, centimetres, or whatever the exporter invented.
    var realHeight: Measurement<UnitLength>

    /// The pass-through camera alone only gives us device pose, so plane detection
    /// has to be asked for separately — and the session has to outlive the request.
    @State private var session = SpatialTrackingSession()

    /// Taps move this, not the loaded geometry, so the scale and grounding offset computed
    /// once at load time survive every reposition.
    @State private var pivot = Entity()

    @State private var isPlaced = false

    var body: some View {
        RealityView { content in
            content.camera = .spatialTracking

            let anchor = AnchorEntity(
                .plane(.horizontal, classification: .any, minimumBounds: [0.2, 0.2]),
                trackingMode: .once
            )
            content.entities.append(anchor)

            // An invisible slab lying over the detected surface. A tap needs *something* with
            // a collision shape to land on, and the real-world plane isn't an entity — no
            // ModelComponent, so it never renders, but hit testing still sees it.
            let surface = Entity()
            surface.components.set(InputTargetComponent())
            surface.components.set(
                CollisionComponent(shapes: [.generateBox(width: 40, height: 0.01, depth: 40)])
            )
            anchor.addChild(surface)

            // Hidden until the first tap says where it goes.
            pivot.isEnabled = false
            anchor.addChild(pivot)

            if let model = try? await Entity(named: modelName) {
                pivot.addChild(model)

                // Measure what we got, scale so its height equals the real object's. One
                // uniform factor, so width and depth stay in proportion.
                let measured = model.visualBounds(relativeTo: pivot).extents.y
                let target = Float(realHeight.converted(to: .meters).value)
                if measured > 0 { model.scale *= target / measured }

                // Re-measure after scaling, then centre the model over the pivot and sit it
                // *on* the surface — so the tap lands under the object's feet, not its middle.
                let bounds = model.visualBounds(relativeTo: pivot)
                model.position.x -= bounds.center.x
                model.position.y -= bounds.min.y
                model.position.z -= bounds.center.z
            }
        }
        .ignoresSafeArea()
        .gesture(place)
        .overlay(alignment: .top) { hint }
        .task { _ = await session.run(.init(tracking: [.plane])) }
    }

    /// Tapping the invisible surface hands us a screen point, which unprojects back onto the
    /// geometry that was actually hit — the spot on the floor under the user's finger.
    private var place: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                guard let spot = value.unproject(\.location, to: .scene) else { return }
                pivot.setPosition(spot, relativeTo: nil)
                pivot.isEnabled = true
                isPlaced = true
            }
    }

    /// Without this the screen is a bare camera feed and nothing tells you to tap.
    @ViewBuilder
    private var hint: some View {
        if !isPlaced {
            Text("Aim at the floor, then tap to place")
                .font(.callout)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(.regularMaterial, in: .capsule)
                .padding(.top, 8)
        }
    }
}
