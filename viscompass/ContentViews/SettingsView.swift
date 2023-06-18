//
//  SettingsView.swift
//  viscompass
//
//  Created by Matt Clark on 10/5/2023.
//

import Foundation
import SwiftUI

let settingsHelpText =
"""
The settings view aloows you to configure basic behaviours of the app.

The "On course feedback" picker lets you choose between a steady drumbeat, a heading readout, and no feedback when the boat is on course.

The "Tack through" picker sets the amount the target is changed by when long pressing on the target adjustment buttons on the steering view.

The "North type" picker lets you chose between true and magnetic north.  True north is only available if the app has permission to access the location of the phone so it can look up the local variation.

The "Target buttons adjust by" picker changes how much the plus and minus buttons on the sterring view change the target heading by.

The "Seconds between heading readouts" picker adjusts the gap between heading readouts in both the compass view and the steering view.
"""

struct SettingsView: View {
    var body: some View {
        VStack {
            HeaderView(helpTitle: "Settings Help", helpText: settingsHelpText, showHeading: true)
            Spacer()
            FeedbackPickerView().padding([.top], 20)
            TackDegreesView().padding([.top], 20)
            NorthTypePickerView().padding([.top], 20)
            TargetAdjustView().padding([.top], 20)
            HeadingSecsView().padding([.top], 20)
            ResetTargetWithAudioView().padding([.top], 20)
            Spacer()
        }
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

struct ResetTargetWithAudioView: View {
    @StateObject var storage = SettingsStorage()
    
    var body: some View {
        VStack(alignment:.leading) {
            Toggle("Reset target when enabling audio", isOn: storage.$resetTargetWithAudio)
        }
    }
}
