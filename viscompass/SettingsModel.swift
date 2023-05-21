//
//  SettingsModel.swift
//  viscompass
//
//  Created by Matt Clark on 18/5/2023.
//

import Foundation

class SettingsModel: ObservableObject {
    @Published var defaultTolerance = 0
    @Published var defaultResponsiveness = 0
    @Published var defaultFeedbackType = 0
    @Published var tackDegrees = 100
    @Published var targetAdjustDegrees = 10
    @Published var northType: northtype = .magneticnorth
    @Published var smoothCompassHeading = true
}

