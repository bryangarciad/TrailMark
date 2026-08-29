//
//  ContentView.swift
//  TrailMark_CH9
//
//  Created by Ramses Garcia on 03/08/26.
//
//  The iOS root: one tab per build. HealthKit authorization is requested once on
//  launch, then today's data loads and gets mirrored to the wrist.
//

import SwiftUI
import TrailMarkCore

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TabView {
            TodayDashboardView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            FieldJournalView()
                .tabItem { Label("Journal", systemImage: "waveform") }

            RecoveryView()
                .tabItem { Label("Recovery", systemImage: "bed.double.fill") }

            JourneyListView()
                .tabItem { Label("Journeys", systemImage: "map.fill") }
        }
        .task {
            await model.health.requestAuthorization()
            await model.health.refreshToday()
            model.mirrorTodayToWatch()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
