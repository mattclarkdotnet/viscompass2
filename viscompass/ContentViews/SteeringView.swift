//
//  SteeringView.swift
//  viscompass
//
//  Created by Matt Clark on 10/5/2023.
//

import Foundation
import SwiftUI

let steeringHelpText =
"""
The steering view gives audio feedback to guide you to a target heading.

To adjust the target heading use the buttons labelled "plus" and "minus" to change it in increments of 10 degrees.  This amount can be changed in the settings view.

To set the target to the current heading, hold down on the target for 2 seconds.

To tack, hold down on the plus or minus button for 2 seconds.  The degrees to tack through are set in the settings view.

When the boat is on course a feedback sound is played to reassure the helm.  To change the on course feedback sound go to the settings view.

When the boat is off course audio feedback will be given and the large coloured arrows will give visual feedback.  The tolerance picker is used to decide how far the boat needs to be off course before off course feedback is given.  The more the boat is off course the more insistent the feedback becomes.

The responsiveness picker is used to set how rapidly the app resposnds to changes in heading.  For a saling boat in swell consider using super-slow or slow responsiveness.  For a motor boat in calm water consider using quick or very quick responsiveness.
"""

struct SteeringView: View {
    @EnvironmentObject var steeringModel: SteeringModel

    var body: some View {
        VStack {
            HeaderView(helpTitle: "Steering Help", helpText: steeringHelpText, showHeading: true)
            TargetView()
            VStack {
                Text("Steer").font(.title)
                HStack {
                    Image(systemName: "arrowtriangle.left.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(steeringModel.correctingNow() == .port ? .red : .gray)
                    
                    VStack {
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
