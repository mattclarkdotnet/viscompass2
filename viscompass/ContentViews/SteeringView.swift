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
    @EnvironmentObject var audioFeedbackModel: AudioFeedbackModel
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .frame(width:50, height:50)
                Spacer()
                VStack {
                    Text("Heading").font(.title)
                    Text(Int(steeringModel.headingCurrentTrue).description).font(.largeTitle)
                }
                Spacer()
                Button(action: {
                    audioFeedbackModel.toggleFeedback()
                }) {
                    Image(systemName: audioFeedbackModel.audioFeedbackOn ? "play.circle" : "pause.circle")
                        .resizable()
                        .frame(width:50, height:50)
                }
            }
            Divider()
            VStack {
                Text("Target").font(.title)
                HStack {
                    Button(action: steeringModel.decreaseTarget) {
                        Image(systemName: "minus.rectangle")
                            .resizable()
                            .frame(width:50, height:50)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    VStack {
                        Text(Int(steeringModel.headingTarget).description)
                            .font(.largeTitle)
                            .frame(width: 150)
                    }
                    Spacer()
                    Button(action: steeringModel.increaseTarget) {
                        Image(systemName: "plus.rectangle")
                            .resizable()
                            .frame(width:50, height:50)
                            .foregroundColor(.green)
                    }
                }
            }
            Divider()
            HStack {
                Image(systemName: "arrowtriangle.left.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.red)

                Text(Int(steeringModel.correctionAmount).description).font(.largeTitle)
                    .frame(width: 150)
                Image(systemName: "arrowtriangle.right.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.green)

            }
            Divider()
            VStack {
                Spacer()
                FeedbackPickerView()
                TolerancePickerView()
                ResponsivenessPickerView()
            }
        }
        .padding()
    }
}


struct FeedbackPickerView: View {
//    @EnvironmentObject var audioFeedbackModel: AudioFeedbackModel
    @EnvironmentObject var steeringModel: SteeringModel
    
    @State private var selectedFeedback: OnCourseFeedbackType = .drum // TODO: take from settings

    var body: some View {
        VStack(alignment: .leading) {
            Text("On course feedback")
            Picker("On course feedback", selection: $selectedFeedback) {
                Text("Drum").tag(OnCourseFeedbackType.drum)
                Text("Heading").tag(OnCourseFeedbackType.heading)
                Text("None").tag(OnCourseFeedbackType.off)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedFeedback) {
                feedbackType in
                steeringModel.audioFeedbackModel.setOnCourseFeedbackType(feedbacktype: feedbackType)
                steeringModel.updateModel()
            }
            
        }
    }
}

struct TolerancePickerView: View {
//    @EnvironmentObject var audioFeedbackModel: AudioFeedbackModel
    @EnvironmentObject var steeringModel: SteeringModel
    
    @State private var selectedTolerance = 10
    let options = [5,10,15,20]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Tolerance")
            Picker("Tolerance", selection: $selectedTolerance) {
                ForEach(options, id: \.self) {
                    Text("\($0)º").tag(Double($0))
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTolerance) {
                tolerance in
                steeringModel.setTolerance(newTolerance: Double(tolerance))
                steeringModel.audioFeedbackModel.updateAudioFeedback(urgency: steeringModel.correctionUrgency, direction: steeringModel.correctionDirection, heading: steeringModel.headingSmoothed)
            }
        }
    }
}

struct ResponsivenessPickerView: View {
    @State private var choice = ""
    var options = ["SS", "S", "M", "Q", "QQ"]

    var body: some View {
        VStack(alignment:.leading) {
            Text("Responsiveness")
            Picker("Responsiveness", selection: $choice) {
                ForEach(options, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
