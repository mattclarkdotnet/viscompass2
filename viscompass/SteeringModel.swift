//
//  SteeringModel.swift
//  viscompass
//
//  Created by Matt Clark on 9/5/2023.
//

import Foundation
import CoreLocation

class CompassModel: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    let headingUpdatesTrue = HeadingFilter()
    let headingUpdatesMagnetic = HeadingFilter()
    
    override init() {
        super.init()
        // Receive heading updates bigger than 1 degree
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.headingFilter = 1.0    // minimum change in degrees to generate an event
        locationManager.startUpdatingHeading()
    }
    
    //CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingUpdatesTrue.add_reading(value: newHeading.trueHeading)
        headingUpdatesMagnetic.add_reading(value: newHeading.magneticHeading)
    }
}




class SteeringModel: ObservableObject {
    @Published private(set) var headingSmoothed: WholeDegrees = 0  // these published values use Int as they are displayed in that format
    @Published private(set) var headingTarget: WholeDegrees = 0
    @Published private(set) var correctionAmount: WholeDegrees = 0
    @Published private(set) var audioFeedbackOn: Bool = false
    @Published private(set) var correctionDirection: Turn = .none
    
    // Marking these published but private so the views invalidate when they change, but they aren't observed directly
    @Published private var toleranceDegrees: WholeDegrees = 10
    @Published private var correctionUrgency: Int = 0 // restricted to between 0 and 3
    
    private var responsivenessIndex: Int
    private var northType: NorthType
    private var tackDegrees: Int
    private var targetAdjustDegrees: Int
    private var modelUpdateTimer: Timer?
    private let store = SettingsStorage()
    private let compassModel = CompassModel()
    var audioFeedbackModel: AudioFeedbackModel? = nil // will be set on load by the main view
    
    
    init() {
        // Configure based on last used settings
        responsivenessIndex = store.responsivenessIndex
        toleranceDegrees = max(store.toleranceDegrees, 5)
        northType = store.northType
        tackDegrees = store.tackDegrees
        targetAdjustDegrees = store.targetAdjustDegrees

        // Update the model once a second.  This different from the underlying CompassModel, which updates on changes in heading
        // The smoothed/filtered value used by the model will update even in the absence of new heading updates
        modelUpdateTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                  target: self,
                                                  selector: #selector(SteeringModel.updateModel),
                                                  userInfo: nil,
                                                  repeats: true)
    }
    
    func setResponsiveness(_ index: Int) {
        responsivenessIndex = index
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
        if audioFeedbackModel != nil {
            audioFeedbackOn = audioFeedbackModel!.toggleFeedback()
        }
        
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
        let observations = northType == .truenorth ? compassModel.headingUpdatesTrue : compassModel.headingUpdatesMagnetic
        
        let newHeadingSmoothed = WholeDegrees(observations.filtered(sensitivityIndex: responsivenessIndex).rounded()).normalised() // rounded to nearest or away from Zero, then normalised to 0-360 range
        if newHeadingSmoothed != headingSmoothed {
            headingSmoothed = newHeadingSmoothed
            audioFeedbackModel?.updateHeadingPhrase(heading: headingSmoothed)
        }
        let newCorrectionAmount = headingSmoothed.bearingTo(to: headingTarget)
        if newCorrectionAmount != correctionAmount {
            correctionAmount = newCorrectionAmount
            correctionDirection = abs(correctionAmount) < toleranceDegrees ? Turn.none : correctionAmount < 0 ? Turn.port : Turn.stbd
        }
        // urgency could have changed if tolerance was changed, even if the heading and correction did not
        correctionUrgency = urgency(correction: correctionAmount, tolerance: toleranceDegrees) // correction urgency can be between 0 (within tolerance window) and 3 (off by 3 x tolerance window or more)
        audioFeedbackModel?.updateUrgencyAndDirection(urgency: correctionUrgency, direction: correctionDirection)
    }
}
