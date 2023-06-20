//
//  HeaderView.swift
//  viscompass2
//
//  Created by Matt Clark on 11/6/2023.
//

import Foundation
import SwiftUI

struct HeaderView: View {
    let helpTitle: String
    let helpText: String
    let showHeading: Bool
    
    @EnvironmentObject var steeringModel: SteeringModel
    @State private var showingHelp = false
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { showingHelp = true }) {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width:50, height:50)
                }
                .accessibilityInputLabels(["Help"])
                .sheet(isPresented: $showingHelp) {
                    VStack {
                        ScrollView {
                            HStack {
                                Button(action: { showingHelp = false }) {
                                    Image(systemName: "x.circle")
                                        .resizable()
                                        .frame(width:25, height:25)
                                }.accessibilityInputLabels(["Close", "Close help"])
                                Spacer()
                            }
                            Text(helpTitle).font(.system(.title)).padding([.bottom], 20)
                            Text(helpText)
                            Text("[Click for online documentation](https://viscompass.org/)").padding([.top], 20)
                            Spacer()
                        }
                    }.padding()
                }
                Spacer()
                Text(showHeading ? "\(Int(steeringModel.headingSmoothed).description)º" : " ").font(.system(size: 50))
                Spacer()
                Button(action: {
                    steeringModel.toggleAudioFeedback()
                })
                {
                    Image(systemName: steeringModel.audioFeedbackOn ? "pause.circle" : "play.circle")
                        .resizable()
                        .frame(width:50, height:50)
                }.accessibilityInputLabels(["Audio", "Audio on off", "Pause", "Start", "Stop", "Pause Audio", "Start Audio", "Stop audio", "Feedback"])
            }
            Divider()
        }
    }
}
