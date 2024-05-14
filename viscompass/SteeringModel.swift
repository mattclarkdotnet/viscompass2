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

typealias WholeDegrees = Int

extension WholeDegrees {
    // Returns our value constrained to compass values, that is to say between zero and 360 (0 <= v < 360)
    func normalised() -> Self {
        let r = self % 360
        return r < 0 ? r + 360 : r
    }
    
    // Returns the bearing or "steering difference" between our value and another value.
    // This is a natural idea in sailing but requires the handling of some edge cases
    // examples:
    // 350.steeringDifference(to: 10) -> 20
    // 10.steeringDifference(to: 350) -> -20
    // 10.steeringDifference(to: 40) -> 30
    // 10.steeringDifference(to: 180) -> 170
    // 10.steeringDifference(to: 200) -> -170
    // 185.steeringDifference(to: 195) -> 10
    func bearingTo(to: Self) -> Self {
        let rawDiff = (to.normalised() - self.normalised()).normalised()
        return rawDiff > 180 ? rawDiff - 360 : rawDiff
    }
}


class SteeringModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private (set) var headingSmoothed: WholeDegrees = 0  // these published values use Int as they are displayed in that format
    @Published private (set) var headingTarget: WholeDegrees = 0
    @Published private (set) var correctionAmount: WholeDegrees = 0
    @Published private (set) var audioFeedbackOn: Bool = false
    @Published private (set) var correctionDirection: Turn = .none
    
    // Marking these published but private so the views invalidate when they change, but they aren't observed directly
    @Published private var toleranceDegrees: WholeDegrees = 10
    
    private var correctionUrgency: Int = 0 // restricted to between 0 and 3
    private var responsivenessIndex: Int
    private var northType: NorthType
    private var tackDegrees: Int
    private var targetAdjustDegrees: Int
    
    private let locationManager: CLLocationManager
    private let headingUpdatesTrue = HeadingFilter()
    private let headingUpdatesMagnetic = HeadingFilter()
    
    private let store = SettingsStorage()
    
    private var headingUpdateTimer: Timer?
    
    let audioFeedbackModel: AudioFeedbackModel
    
    override init() {
        // TODO: deal with location manager heading service not being available
        locationManager = CLLocationManager()
        audioFeedbackModel = AudioFeedbackModel()
        
        // Configure based on last used settings

        responsivenessIndex = store.responsivenessIndex
        toleranceDegrees = max(store.toleranceDegrees, 5)
        northType = store.northType
        tackDegrees = store.tackDegrees
        targetAdjustDegrees = store.targetAdjustDegrees
        //audioFeedbackModel.updateAudioFeedback()

        super.init() // do this after loading defaults from storage
        
        // Receive heading updates bigger than 1 degree
        locationManager.delegate = self
        locationManager.headingFilter = 1.0    // minimum change in degrees to generate an event
        locationManager.startUpdatingHeading()
        
        // Update the model once a second.  This also causes the filtered heading to be updated
        // which is important, because the filtered value converges over time, so we can't just
        // update it when a new value arrives
        headingUpdateTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                  target: self,
                                                  selector: #selector(SteeringModel.updateModel),
                                                  userInfo: nil,
                                                  repeats: true)
    }
    
    func setResponsiveness(_ index: Int) {
        responsivenessIndex = index
        logger.debug("new responsiveness: \(index.description)")
    }
    
    func setNorthType(newNorthType: NorthType) {
        northType = newNorthType
        updateModel()
    }
    
    func setTackDegrees(newTackDegrees: Int) {
        // No need to update the model as this is only used when a tack is initiated
        tackDegrees = newTackDegrees
    }
    
    func setTargetAdjustDegrees(targetAdjustDegrees: Int) {
        self.targetAdjustDegrees = targetAdjustDegrees
    }
    
    func toggleAudioFeedback() {
        if !audioFeedbackOn && store.resetTargetWithAudio {
            setTarget(target: headingSmoothed)
        }
        audioFeedbackOn = audioFeedbackModel.toggleFeedback()
        
    }
    
    func increaseTarget() {
        headingTarget = (headingTarget + targetAdjustDegrees).normalised()
        updateModel()
    }
    
    func decreaseTarget() {
        headingTarget = (headingTarget - targetAdjustDegrees).normalised()
        updateModel()
    }
    
    func setTarget(target: Int) {
        headingTarget = target.normalised()
        updateModel()
    }
    
    func tack(turn: Turn) {
        let amount = turn == .stbd ? tackDegrees : -tackDegrees
        headingTarget = (headingTarget + amount).normalised()
        updateModel()
    }
    
    func setTolerance(newTolerance: Int) {
        toleranceDegrees = newTolerance
        updateModel()
    }
    
    private func urgency(correction: Int, tolerance: Int) -> Int {
        return min(abs(correctionAmount) / tolerance, 3)
    }
    
    @objc func updateModel() {
        let observations = northType == .truenorth ? headingUpdatesTrue : headingUpdatesMagnetic
        
        let newHeadingSmoothed = WholeDegrees(observations.filtered(sensitivityIndex: responsivenessIndex).rounded()).normalised() // rounded to nearest or away from Zero, then normalised to 0-360 range
        if newHeadingSmoothed != headingSmoothed {
            headingSmoothed = newHeadingSmoothed
            audioFeedbackModel.updateHeading(heading: headingSmoothed)
        }
        let newCorrectionAmount = headingSmoothed.bearingTo(to: headingTarget)
        if newCorrectionAmount != correctionAmount {
            correctionAmount = newCorrectionAmount
            correctionDirection = abs(correctionAmount) < toleranceDegrees ? Turn.none : correctionAmount < 0 ? Turn.port : Turn.stbd
        }
        // urgency could have changed if tolerance was changed, even if the heading and correction did not
        correctionUrgency = urgency(correction: correctionAmount, tolerance: toleranceDegrees) // correction urgency can be between 0 (within tolerance window) and 3 (off by 3 x tolerance window or more)
        audioFeedbackModel.updateUrgencyAndDirection(urgency: correctionUrgency, direction: correctionDirection)
    }
    
    //CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingUpdatesTrue.add_reading(value: newHeading.trueHeading)
        headingUpdatesMagnetic.add_reading(value: newHeading.magneticHeading)
    }
}
