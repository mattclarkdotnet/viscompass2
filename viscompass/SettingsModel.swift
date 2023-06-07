//
//  SettingsModel.swift
//  viscompass
//
//  Created by Matt Clark on 18/5/2023.
//

import Foundation
import SwiftUI


class SettingsStorage: ObservableObject {
    @AppStorage("responsivenessIndex") public var responsivenessIndex = 2
    @AppStorage("toleranceDegrees") public var toleranceDegrees = 10
    @AppStorage("feedbackType") public var feedbackType: OnCourseFeedbackType = .drum
    @AppStorage("headingSecs") public var headingSecs = 10
    @AppStorage("tackDegrees") public var tackDegrees = 100
    @AppStorage("targetAdjustDegrees") public var targetAdjustDegrees = 10
    @AppStorage("northType") public var northType: NorthType = .magneticnorth
}
