//
//  MotionView.swift
//  TrailMarkCompanion Watch App
//
//  Course 2.4 — sensing motion at the source. Surfaces a derived signal
//  (cadence + activity type) from Core Motion via the shared MotionManager. The
//  wrist is the ideal place to sense motion; the cost of always-on sampling is
//  the conversation Course 3.3 picks up.
//

import SwiftUI
import TrailmarkCore

struct MotionView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: model.motion.activity.symbolName)
                        .font(.title2)
                        .foregroundStyle(.teal)
                    Text(model.motion.activity.label)
                        .font(.headline)
                }
            } header: {
                Text("Activity")
            }

            Section {
                LabeledContent("Cadence", value: "\(Int(model.motion.cadence)) spm")
                LabeledContent("Steps", value: "\(model.motion.stepsToday)")
                LabeledContent("Accel", value: String(format: "%.2f g", model.motion.accelerationMagnitude))
            } header: {
                Text("Derived signals")
            }
        }
        .navigationTitle("Motion")
        .onAppear { model.motion.start() }
        .onDisappear { model.motion.stop() }
    }
}
