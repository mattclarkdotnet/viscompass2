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
The steering view gives audio feedback to help you stay on target heading. See the online help guide (document link below) for how to set up the phone running the app on board a yacht.

To adjust the target heading use the buttons labelled "plus" and "minus" to change it in increments of 10 degrees.  This amount can be changed in the settings view.

To conveniently set the target to the current heading, hold down on the target for 2 seconds until a blue circle appears around it.

To tack, hold down on the plus or minus button for 2 seconds.  The degrees to tack through are set in the settings view.

When the boat is on course a feedback sound is played to reassure the helm.  To change the on course feedback sound go to the settings view.

When the boat is off course, audio feedback will be given - high pitched "chickens" mean correct to starboard , low pitched ducks mean correct to port. The large coloured arrows will give visual feedback.  The tolerance picker is used to decide how far the boat needs to be off course before off course feedback is given.  The more the boat is off course the more insistent the feedback becomes.

The tolerance picker is used to set how far away from the target heading the boat needs to be before the off-course warnings start.

The responsiveness picker is used to set how rapidly the app resposnds to changes in heading.  For a sailing boat in swell consider using super-slow or slow responsiveness.  For a motor boat in calm water consider using quick or very quick responsiveness.
"""

struct SteeringView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    @EnvironmentObject var audioFeedbackModel: AudioFeedbackModel
    
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
                        .foregroundColor(steeringModel.correctionDirection == .port ? .red : .gray)
                    
                    VStack {
                        Text(Int(steeringModel.correctionAmount).description + "º")
                            .font(.system(size: 45))
                            .monospacedDigit()
                    }.frame(minWidth: 130)
                    Image(systemName: "arrowtriangle.right.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(steeringModel.correctionDirection == .stbd ? .green : .gray)
                    
                }
            }
            Spacer()
            VStack {
                TolerancePickerView()
                ResponsivenessPickerView().padding([.top], 20)
            }
        }
        .padding(5)
        .onAppear(perform: { audioFeedbackModel.updateFeedbackMode(mode: .steering) })
    }
}


struct Previews_SteeringView_Previews: PreviewProvider {
    static var previews: some View {
        SteeringView()
            .environmentObject(SteeringModel())
            .environmentObject(AudioFeedbackModel())
    }
}
