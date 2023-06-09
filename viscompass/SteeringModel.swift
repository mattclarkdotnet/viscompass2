//
//  SteeringModel.swift
//  viscompass
//
//  Created by Matt Clark on 9/5/2023.
//

import Foundation
import CoreLocation

enum NorthType: String {
    case truenorth = "true"
    case magneticnorth = "magnetic"
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
    @Published private (set) var headingSmoothed: CLLocationDegrees = 0
    @Published private (set) var headingTarget: CLLocationDegrees = 0
    @Published private (set) var correctionAmount: CLLocationDegrees = 0
    @Published private (set) var audioFeedbackOn: Bool = false
    
    // Marking these published but private so the views invalidate when they change, but they aren't observed directly
    @Published private var toleranceDegrees: CLLocationDegrees = 10
    
    private var headingCurrentTrue: CLLocationDegrees = 0
    private var headingCurrentMagnetic: CLLocationDegrees = 0
    private var correctionUrgency: Int = 0 // restricted to between 0 and 3
    private var correctionDirection: Turn = .none
    private var responsivenessIndex: Int
    private var northType: NorthType
    private var tackDegrees: CLLocationDegrees
    private var targetAdjustDegrees: CLLocationDegrees
    
    private let locationManager: CLLocationManager
    private let responsivenessWindows: [Double] = [10.0, 6.0, 3.0, 1.5, 0.75]
    private let headingUpdatesTrue = HeadingFilter()
    private let headingUpdatesMagnetic = HeadingFilter()
    
    private var headingUpdateTimer: Timer?
    
    let audioFeedbackModel: AudioFeedbackModel
    
    override init() {
        // TODO: deal with location manager heading service not being available
        locationManager = CLLocationManager()
        audioFeedbackModel = AudioFeedbackModel()
        
        logger.debug("Gammas: \(gammas)")
        
        // Configure based on last used settings
        let store = SettingsStorage()
        responsivenessIndex = store.responsivenessIndex
        toleranceDegrees = max(CLLocationDegrees(store.toleranceDegrees), 5)
        northType = store.northType
        tackDegrees = CLLocationDegrees(store.tackDegrees)
        targetAdjustDegrees = CLLocationDegrees(store.targetAdjustDegrees)
        
        audioFeedbackModel.setOnCourseFeedbackType(feedbacktype: store.feedbackType)
        audioFeedbackModel.updateHeading(heading: 0)
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 1.0    // minimum change in degrees to generate an event
        locationManager.startUpdatingHeading()
        headingUpdateTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                  target: self,
                                                  selector: #selector(SteeringModel.updateModel),
                                                  userInfo: nil,
                                                  repeats: true)
    }
    
    func correctingNow() -> Turn {
        if correctionUrgency > 0 {
            return correctionDirection
        }
        else {
            return .none
        }
    }
    
    func setResponsiveness(_ index: Int) {
        responsivenessIndex = index
        logger.debug("new responsiveness: \(index.description)")
    }
    
    func setNorthType(newNorthType: NorthType) {
        northType = newNorthType
        updateModel()
    }
    
    func setTackDegrees(newTackDegrees: CLLocationDegrees) {
        tackDegrees = newTackDegrees
    }
    
    func setTargetAdjustDegrees(targetAdjustDegrees: CLLocationDegrees) {
        self.targetAdjustDegrees = targetAdjustDegrees
    }
    
    func toggleAudioFeedback() {
        audioFeedbackModel.toggleFeedback()
        audioFeedbackOn = audioFeedbackModel.audioFeedbackOn
        // No need to update the model here, as the audio model keeps running but just doesn't play any sounds
    }
    
    func increaseTarget() {
        headingTarget = (headingTarget + targetAdjustDegrees).truncatingRemainder(dividingBy: 360.0)
        updateModel()
    }
    
    func decreaseTarget() {
        headingTarget = (headingTarget - targetAdjustDegrees).truncatingRemainder(dividingBy: 360.0)
        updateModel()
    }
    
    func setTarget(target: CLLocationDegrees) {
        headingTarget = target.truncatingRemainder(dividingBy: 360.0)
        updateModel()
    }
    
    func tack(turn: Turn) {
        let amount = turn == .stbd ? tackDegrees : -tackDegrees
        headingTarget = (headingTarget + amount).truncatingRemainder(dividingBy: 360.0)
        updateModel()
    }
    
    func setTolerance(newTolerance: CLLocationDegrees) {
        toleranceDegrees = min(newTolerance.truncatingRemainder(dividingBy: 360.0), 5)
        updateModel()
    }
    
    private func urgency(correction: CLLocationDegrees, tolerance: CLLocationDegrees) -> Int {
        return min(Int(abs(correctionAmount / tolerance)), 3)
    }
    
    @objc func updateModel() {
        let observations = northType == .truenorth ? headingUpdatesTrue : headingUpdatesMagnetic
        headingSmoothed = observations.filtered(gamma: gammas[responsivenessIndex])
        correctionAmount = correctionDegrees(headingSmoothed, target: headingTarget)
        correctionDirection = correctionAmount < 0 ? Turn.port : Turn.stbd
        correctionUrgency = urgency(correction: correctionAmount, tolerance: toleranceDegrees) // correction urgency can be between 0 (within tolerance window) and 3 (off by 3 x tolerance window or more)
        audioFeedbackModel.updateHeading(heading: headingSmoothed)
        audioFeedbackModel.updateUrgencyAndDirection(urgency: correctionUrgency, direction: correctionDirection)
    }
    
    //CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingCurrentTrue = newHeading.trueHeading
        headingCurrentMagnetic = newHeading.magneticHeading
        headingUpdatesTrue.add_reading(value: headingCurrentTrue)
        headingUpdatesMagnetic.add_reading(value: headingCurrentMagnetic)
        // Don't explicitly update the model, it will happen every second on a timer
    }
}
