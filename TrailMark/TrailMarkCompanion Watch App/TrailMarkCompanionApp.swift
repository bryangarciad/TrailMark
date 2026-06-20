//
//  TrailMarkCompanionApp.swift
//  TrailMarkCompanion Watch App
//
//  Created by Ramses Garcia on 20/06/26.
//

import SwiftUI

@main
struct TrailMarkCompanion_Watch_AppApp: App {
    @State private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}
