//
//  SettingsView.swift
//  viscompass
//
//  Created by Matt Clark on 10/5/2023.
//

import Foundation
import SwiftUI

struct SettingsView: View {
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
            Text("Global settings")
                .font(.largeTitle)
                .padding(EdgeInsets(top:10, leading:10, bottom:20, trailing:10))
            NorthTypePickerView()
            TackDegreesView()
            TargetAdjustView()
            HeadingSecsView()
            Spacer()
        }
        .padding()
    }
}

struct NorthTypePickerView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    @StateObject var storage = SettingsStorage()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("North type")
            Picker("North type", selection: $storage.northType) {
                Text("True").tag(NorthType.truenorth)
                Text("Magnetic").tag(NorthType.magneticnorth)
            }
            .pickerStyle(.segmented)
            .onChange(of: storage.northType) {
                northType in
                steeringModel.setNorthType(newNorthType: northType)
            }
        }
    }
}

struct TackDegreesView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    @StateObject var storage = SettingsStorage()
    let options = [90,100,110,120,130]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Tack through")
            Picker("Tack through", selection: $storage.tackDegrees) {
                ForEach(options, id: \.self) {
                    Text("\($0)º").tag($0)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: storage.tackDegrees) {
                tackDegrees in
                steeringModel.setTackDegrees(newTackDegrees: Double(tackDegrees))
            }
        }
    }
}

struct HeadingSecsView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    @StateObject var storage = SettingsStorage()
    let options = [5,10,15,20,30]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Seconds between heading readouts")
            Picker("Seconds", selection: $storage.headingSecs) {
                ForEach(options, id: \.self) {
                    Text("\($0)").tag($0)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: storage.headingSecs) {
                headingSecs in
                steeringModel.audioFeedbackModel.updateHeadingSecs(secs: headingSecs)
            }
        }
    }
}

struct TargetAdjustView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    @StateObject var storage = SettingsStorage()
    let options = [2,5,10,20]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Target buttons adjust by")
            Picker("Target adjust", selection: $storage.targetAdjustDegrees) {
                ForEach(options, id: \.self) {
                    Text("\($0)º").tag($0)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: storage.targetAdjustDegrees) {
                targetAdjustDegrees in
                steeringModel.setTargetAdjustDegrees(targetAdjustDegrees: Double(targetAdjustDegrees))
            }
        }
    }
}


struct FeedbackPickerView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    @StateObject var storage = SettingsStorage()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("On course feedback")
            Picker("On course feedback", selection: $storage.feedbackType) {
                Text("Drum").tag(OnCourseFeedbackType.drum)
                Text("Heading").tag(OnCourseFeedbackType.heading)
                Text("None").tag(OnCourseFeedbackType.off)
            }
            .pickerStyle(.segmented)
            .onChange(of: storage.feedbackType) {
                feedbackType in
                steeringModel.audioFeedbackModel.setOnCourseFeedbackType(feedbacktype: feedbackType)
                steeringModel.updateModel()
            }
        }
    }
}

struct TolerancePickerView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    @StateObject var storage = SettingsStorage()
    let options = [5,10,15,20]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Tolerance")
            Picker("Tolerance", selection: storage.$toleranceDegrees) {
                ForEach(options, id: \.self) {
                    Text("\($0)º").tag($0)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: storage.toleranceDegrees) {
                tolerance in
                steeringModel.setTolerance(newTolerance: Double(tolerance))
            }
        }
    }
}


struct ResponsivenessPickerView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    @StateObject var storage = SettingsStorage()
    let options = ["SS", "S", "M", "Q", "QQ"]
    
    var body: some View {
        VStack(alignment:.leading) {
            Text("Responsiveness")
            Picker("Responsiveness", selection: storage.$responsivenessIndex) {
                ForEach(0..<5) {i in
                    Text(options[i]).tag(i)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: storage.responsivenessIndex) {
                newResponsiveness in
                steeringModel.setResponsiveness(newResponsiveness)
            }
        }
    }
}
