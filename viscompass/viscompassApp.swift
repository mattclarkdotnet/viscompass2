//
//  viscompassApp.swift
//  viscompass
//
//  Created by Matt Clark on 6/5/2023.
//

import SwiftUI
import os

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: "VISCompass"))

@main
struct viscompassApp: App {
    @StateObject var steeringModel = SteeringModel()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(steeringModel)
        }
    }
}
