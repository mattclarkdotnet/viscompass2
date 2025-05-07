//
//  MainView.swift
//  viscompass
//
//  Created by Matt Clark on 6/5/2023.
//

import SwiftUI

struct MainView: View {
    @State private var selection: Tab = .navigation
    @EnvironmentObject var steeringModel: SteeringModel
    @EnvironmentObject var audioFeedbackModel: AudioFeedbackModel
    
    enum Tab {
        case navigation
        case compass
        case settings
    }
    
    var body: some View {
        TabView() {
            SteeringView()
                .tabItem {
                    Label("Steer", systemImage: "helm")
                }
                .padding([.bottom], 30)
                .tag(Tab.navigation)
            CompassView()
                .tabItem {
                    Label("Compass", systemImage: "arrow.up.circle")
                }
                .padding([.bottom], 30)
                .tag(Tab.compass)
            SettingsView()
                .padding([.bottom], 30)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .padding(EdgeInsets(top: 5, leading: 15, bottom: 0, trailing: 15))
        .onAppear() {
            UIApplication.shared.isIdleTimerDisabled = true // When VISCompass is running in the foreground, the phone will not dim the display or go to the lock screen
            steeringModel.audioFeedbackModel = audioFeedbackModel
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(SteeringModel())
    }
}
