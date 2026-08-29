import SwiftUI
import RealityKit

@MainActor
struct ARModelView: View {

    var modelName: String
    var realHeight: Measurement<UnitLength>
    var maxTapDistance: Measurement<UnitLength> = .init(value: 3, unit: .meters)


    @State private var session = SpatialTrackingSession()


    @State private var anchor = AnchorEntity(
        .plane(.horizontal, classification: .any, minimumBounds: [0.1, 0.1]),
        trackingMode: .once
    )

    @State private var isSurfaceReady = false
    @State private var pivot = Entity()
    @State private var surface = Entity()
    @State private var isPlaced = false

    @State private var yaw: Float = 0
    @State private var committedYaw: Float = 0

    var body: some View {
        RealityView { content in
            content.camera = .spatialTracking
            content.entities.append(anchor)

            surface.components.set(InputTargetComponent())

            surface.components.set(
                CollisionComponent(shapes: [
                    .generateBox(width: 8, height: 0.01, depth: 8)
                        .offsetBy(translation: [0, -0.005, 0])
                ])
            )
            anchor.addChild(surface)

            pivot.isEnabled = false
            anchor.addChild(pivot)

            if let model = try? await Entity(named: modelName) {
                pivot.addChild(model)


                let measured = model.visualBounds(relativeTo: pivot).extents.y
                let target = Float(realHeight.converted(to: .meters).value)
                if measured > 0 { model.scale *= target / measured }


                let bounds = model.visualBounds(relativeTo: pivot)
                model.position.x -= bounds.center.x
                model.position.y -= bounds.min.y
                model.position.z -= bounds.center.z

                let size = model.visualBounds(relativeTo: pivot).extents
                pivot.components.set(InputTargetComponent())
                pivot.components.set(
                    CollisionComponent(shapes: [
                        .generateBox(size: size).offsetBy(translation: [0, size.y / 2, 0])
                    ])
                )
            }
        }
        .ignoresSafeArea()
        .gesture(place)
        .simultaneousGesture(spin)
        .overlay(alignment: .top) { hint }
        .task {
            _ = await session.run(.init(tracking: [.plane]))
            while !Task.isCancelled && !anchor.isAnchored {
                try? await Task.sleep(for: .milliseconds(200))
            }
            isSurfaceReady = anchor.isAnchored
        }
    }

    private var place: some Gesture {
        SpatialTapGesture()
            .targetedToEntity(surface)
            .onEnded { value in
                guard let spot = value.unproject(\.location, to: .scene),
                      let fromLens = value.unproject(\.location, to: .camera),
                      simd_length(fromLens) <= Float(maxTapDistance.converted(to: .meters).value)
                else { return }


                let floorY = surface.position(relativeTo: nil).y
                pivot.setPosition([spot.x, floorY, spot.z], relativeTo: nil)
                pivot.isEnabled = true
                isPlaced = true
            }
    }


    private var spin: some Gesture {
        DragGesture(minimumDistance: 20)
            .targetedToEntity(pivot)
            .onChanged { value in
                yaw = committedYaw + Float(value.translation.width) * 0.01
                pivot.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
            }
            .onEnded { _ in committedYaw = yaw }
    }

    @ViewBuilder
    private var hint: some View {
        if !isPlaced {
            Label(
                isSurfaceReady ? "Tap the floor nearby to place it" : "Move the phone slowly over the floor",
                systemImage: isSurfaceReady ? "hand.tap" : "viewfinder"
            )
                .font(.callout)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(.regularMaterial, in: .capsule)
                .padding(.top, 8)
        }
    }
}
