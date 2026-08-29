//
//  ContentView.swift
//  TrailMarkCompanion Watch App
//
//  Created by Ramses Garcia on 03/08/26.
//

import SwiftUI
import TrailMarkCore

struct ContentView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                WristHomeView()

                Section {
                    NavigationLink {
                        LiveWorkoutView()
                    } label: {
                        Label("Go for a walk", systemImage: "figure.walk")
                    }
                    NavigationLink {
                        LiveVitalsView()
                    } label: {
                        Label("Live vitals", systemImage: "heart.fill")
                    }
                    NavigationLink {
                        WristMemoView()
                    } label: {
                        Label("Voice memo", systemImage: "mic.fill")
                    }
                    NavigationLink {
                        MotionView()
                    } label: {
                        Label("Motion", systemImage: "gyroscope")
                    }
                }
            }
            .navigationTitle("TrailMark")
            .task {
                await model.health.requestAuthorization()
                await model.health.refreshToday()
                model.publishStepsToComplication()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(WatchModel())
}
