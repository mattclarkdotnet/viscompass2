//
//  SteeringModel.swift
//  viscompass
//
//  Created by Matt Clark on 9/5/2023.
//

import Foundation
import CoreLocation

enum northtype {
    case truenorth
    case magneticnorth
}

enum Turn {
    case port
    case stbd
    case none
}

func correctionDegrees(_ current: CLLocationDegrees, target: CLLocationDegrees) -> CLLocationDegrees {
    let diffwith = current > 180 ? current - 360 : current
    let result = target - diffwith
    return result < 180 ? result : result - 360
}

class SteeringModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var headingCurrentTrue: CLLocationDegrees = 0
    @Published var headingCurrentMagnetic: CLLocationDegrees = 0
    @Published var headingSmoothed: CLLocationDegrees = 0
    @Published var headingTarget: CLLocationDegrees = 0
    @Published var correctionAmount: CLLocationDegrees = 0
    @Published var correctionUrgency: Int = 0 // restricted to between 0 and 3
    @Published var correctionDirection: Turn = .none
    @Published private (set) var toleranceDegrees: CLLocationDegrees = 10
    @Published var responsivenessIndex: Int = 2
    
    let audioFeedbackModel: AudioFeedbackModel
    
    private let locationManager: CLLocationManager
    
    private let responsivenessWindows: [Double] = [10.0, 6.0, 3.0, 1.5, 0.75]
    private let headingUpdates: ObservationHistory = ObservationHistory(deltaFunc: correctionDegrees, window_secs: 10)
    
    override init() {
        // TODO: deal with location manager heading service not being available
        locationManager = CLLocationManager()
        audioFeedbackModel = AudioFeedbackModel()
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 1.0    // minimum change in degrees to generate an event
        locationManager.startUpdatingHeading()
        self.updateModel()
    }
    
    func setResponsiveness(_ index: Int) {
        responsivenessIndex = index
        headingUpdates.window_secs = responsivenessWindows[responsivenessIndex]
        logger.debug("new responsiveness: \(self.headingUpdates.window_secs.description)")
    }
    
    func increaseTarget() {
        headingTarget = (headingTarget + 10).truncatingRemainder(dividingBy: 360.0)
        updateModel()
    }
    
    func decreaseTarget() {
        headingTarget = (headingTarget - 10).truncatingRemainder(dividingBy: 360.0)
        updateModel()
    }
    
    func setTolerance(newTolerance: CLLocationDegrees) {
        toleranceDegrees = max(newTolerance.truncatingRemainder(dividingBy: 360.0), 5)
    }
    
    func updateModel() {
        correctionAmount = correctionDegrees(headingUpdates.smoothed(Date()), target: headingTarget)
        correctionDirection = correctionAmount < 0 ? Turn.port : Turn.stbd
        correctionUrgency = min(Int(abs(correctionAmount / toleranceDegrees)), 3) // correction urgency can be between 0 (within tolerance window) and 3 (off by 3 x tolerance window or more)
        audioFeedbackModel.updateAudioFeedback(urgency: correctionUrgency, direction: correctionDirection, heading: headingSmoothed)
    }
    
    //CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingCurrentTrue = newHeading.trueHeading
        headingCurrentMagnetic = newHeading.magneticHeading
        headingUpdates.add_observation(Observation(v: newHeading.trueHeading, t: Date()))
        updateModel()
    }
}
