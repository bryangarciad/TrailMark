//
//  TrailMarkApp.swift
//  TrailMark
//
//  Created by Ramses Garcia on 20/06/26.
//

import SwiftUI

@main
struct TrailMarkApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}
