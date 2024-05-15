//
//  CompassView.swift
//  viscompass
//
//  Created by Matt Clark on 10/5/2023.
//

import Foundation
import SwiftUI

let compassHelpText =
"""
The compass view displays the current heading in a large font, and sets the audio feedback to read out the heading.

Use the responsiveness picker at the bottom of the screen to set how rapidly the heading responds to changes.

Use the settings view to change the frequency of the heading readout
"""


struct CompassView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    @EnvironmentObject var audioFeedbackModel: AudioFeedbackModel
    
    var body: some View {
        VStack {
            HeaderView(helpTitle: "Compass Help", helpText: compassHelpText, showHeading: false)
            Spacer()
            VStack {
                Text("Heading º").font(.title)
                Text(Int(steeringModel.headingSmoothed).description).font(.system(size: 150)).monospacedDigit()
            }.padding(EdgeInsets(top:0, leading:0, bottom:150, trailing:0))
            Spacer()
            HeadingSecsView()
        }
        .padding(5)
        .onAppear(perform: { audioFeedbackModel.updateFeedbackMode(mode: .compass) })
    }

}

struct Previews_CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView()
            .environmentObject(SteeringModel())
    }
}
