//
//  TabView.swift
//  viscompass
//
//  Created by Matt Clark on 6/5/2023.
//

import SwiftUI

struct MainView: View {
//    @EnvironmentObject var audioFeedbackModel: AudioFeedbackModel
//    @EnvironmentObject var steeringModel: SteeringModel
//    
    
    @State private var selection: Tab = .navigation
    enum Tab {
        case navigation
        case compass
        case settings
    }
    
    var body: some View {
        TabView(selection: $selection) {
            SteeringView()
                .tabItem {
                    Label("Steer", systemImage: "helm")
                }
                .tag(Tab.navigation)
            CompassView()
                .tabItem {
                    Label("Compass", systemImage: "arrow.up.circle")
                }
                .tag(Tab.compass)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(SteeringModel())
            .environmentObject(AudioFeedbackModel())
            .environmentObject(SettingsModel())
    }
}
