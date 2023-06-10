//
//  CompassView.swift
//  viscompass
//
//  Created by Matt Clark on 10/5/2023.
//

import Foundation
import SwiftUI


struct CompassView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .frame(width:50, height:50)
                Spacer()
                Text(" ").font(.system(size: 50)) // for layout consistency across views
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
            Spacer()
            VStack {
                Text("Heading º").font(.title)
                Text(Int(steeringModel.headingSmoothed).description).font(.system(size: 150))
            }.padding(EdgeInsets(top:0, leading:0, bottom:150, trailing:0))
            Spacer()
            ResponsivenessPickerView()
        }
        .onAppear(perform: { steeringModel.audioFeedbackModel.setFeedbackMode(mode: .compass) })
    }

}

struct Previews_CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView()
            .environmentObject(SteeringModel())
    }
}
