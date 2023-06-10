//
//  SteeringView.swift
//  viscompass
//
//  Created by Matt Clark on 10/5/2023.
//

import Foundation
import SwiftUI

struct SteeringView: View {
    @EnvironmentObject var steeringModel: SteeringModel

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .frame(width:50, height:50)
                Spacer()
                Text(Int(steeringModel.headingSmoothed).description + "º").font(.system(size: 50))
                Spacer()
                Button(action: {
                    steeringModel.toggleAudioFeedback()
                }) {
                    Image(systemName: steeringModel.audioFeedbackOn ? "pause.circle" : "play.circle")
                        .resizable()
                        .frame(width:50, height:50)
                }
            }
            Divider()
            TargetView()
            Divider()
            Spacer()
            VStack {
                HStack {
                    Image(systemName: "arrowtriangle.left.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(steeringModel.correctingNow() == .port ? .red : .gray)
                    
                    VStack {
                        Text("Steer").font(.title)
                        Text(Int(steeringModel.correctionAmount).description + "º")
                            .font(.system(size: 50))
                    }.frame(minWidth: 130)
                    Image(systemName: "arrowtriangle.right.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(steeringModel.correctingNow() == .stbd ? .green : .gray)
                    
                }
            }
            Spacer()
            VStack {
                TolerancePickerView()
                ResponsivenessPickerView().padding([.top], 20)
            }
        }
        .onAppear(perform: { steeringModel.audioFeedbackModel.setFeedbackMode(mode: .steering) })
    }
}


struct Previews_SteeringView_Previews: PreviewProvider {
    static var previews: some View {
        SteeringView()
            .environmentObject(SteeringModel())
    }
}
