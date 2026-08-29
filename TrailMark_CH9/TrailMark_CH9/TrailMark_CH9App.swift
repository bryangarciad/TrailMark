//
//  TrailMark_CH9App.swift
//  TrailMark_CH9
//
//  Created by Ramses Garcia on 03/08/26.
//

import SwiftUI

@main
struct TrailMark_CH9App: App {
    @State private var model = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}
