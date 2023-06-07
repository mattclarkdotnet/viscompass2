//
//  AudioFeedbackModel.swift
//  viscompass
//
//  Created by Matt Clark on 9/5/2023.
//
//  There's a valid case to be made that these should all be methods on SteeringModel, as so much state is shared,
//  but I'm keeping them separate for now despite the clunkiness. It somehow feels right that audio feedback should be modelled separately
//  even if it does result in state duplication.
//

import Foundation
import AudioToolbox
import AVFoundation

func createSound(_ fileName: String, fileExt: String) -> SystemSoundID {
    var soundID: SystemSoundID = 0
    let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), fileName as CFString, fileExt as CFString, nil)
    AudioServicesCreateSystemSoundID(soundURL!, &soundID)
    return soundID
}

enum AudioFeedbackSound: String {
    case high = "high"
    case low = "low"
    case drum = "drum"
    case heading = "heading"
    case none = "none"
}

enum AudioFeedbackMode: String {
    case compass = "compass"
    case steering = "steering"
}

enum OnCourseFeedbackType: String {
    case drum = "drum"
    case heading = "heading"
    case off = "off"
}


class AudioFeedbackModel { // we don't make this observable, so as to avoid effing around with nested models for SwiftUI
    
    private (set) var headingSecs = 10
    private (set) var audioFeedbackOn: Bool = false
    private (set) var audioFeedbackMode: AudioFeedbackMode = .steering
    private (set) var onCourseFeedbackType: OnCourseFeedbackType = .drum // Just a default, actually gets set from stored prefs by the SteeringModel
    private var feedbackInterval: TimeInterval = 0
    private var feedbackSound: AudioFeedbackSound = .drum // Just a default, actually gets set from stored prefs by the SteeringModel
    private var feedbackHeading: Int = 0
    private var feedbackUrgency: Int = 0
    private var feedbackDirection: Turn = .none
    
    private var audioTimer: Timer?
    
    private let speechSynthesiser: AVSpeechSynthesizer = AVSpeechSynthesizer()
    private let sndHigh: SystemSoundID = createSound("click_high", fileExt: "wav")
    private let sndLow: SystemSoundID = createSound("click_low", fileExt: "wav")
    private let sndNeutral: SystemSoundID = createSound("drum200", fileExt: "wav")
    private var sndHeading: AVSpeechUtterance?
    
    func updateHeading(heading: Double) {
        let headingStr = Int(heading).description // e.g. '130'
        let headingDigits = headingStr.map({"\($0)"})
        sndHeading = AVSpeechUtterance(string: "heading \(headingDigits)")
    }
    
    func updateHeadingSecs(secs: Int) {
        headingSecs = secs
        logger.debug("secs: \(secs)")
        updateAudioFeedback()
    }
    
    func setFeedbackMode(mode: AudioFeedbackMode) {
        audioFeedbackMode = mode
        updateAudioFeedback()
    }
    
    func updateUrgencyAndDirection(urgency: Int, direction: Turn) {
        if urgency == feedbackUrgency && direction == feedbackDirection {
            return
        }
        feedbackUrgency = urgency
        feedbackDirection = direction
        updateAudioFeedback()
    }

    func toggleFeedback() {
        if audioFeedbackOn {
            audioFeedbackOn = false
            audioTimer?.invalidate()
        }
        else {
            audioFeedbackOn = true
            playAudioFeedbackSound() // play a sound immediately upon toggling audio back on
            createTimer()
        }
        logger.debug("Toggled audio feedback, new is \(self.audioFeedbackOn)")
    }
    
    func setOnCourseFeedbackType(feedbacktype: OnCourseFeedbackType) {
        logger.debug("Setting on course feedback type to \(feedbacktype.rawValue)")
        onCourseFeedbackType = feedbacktype
        updateAudioFeedback()
    }
    
    // Private methods
    
    private func createTimer() {
        audioTimer?.invalidate()
        if feedbackInterval > 0 {
            audioTimer = Timer.scheduledTimer(timeInterval: feedbackInterval,
                                              target: self,
                                              selector: #selector(AudioFeedbackModel.playAudioFeedbackSound),
                                              userInfo: nil,
                                              repeats: true)
        }
    }
    
    private func nextSoundAndInterval() -> (AudioFeedbackSound, TimeInterval) {
        if audioFeedbackMode == .compass {
            return (.heading, Double(headingSecs))
        }
        else if feedbackUrgency == 0 {
            // we are within tolerance
            switch onCourseFeedbackType {
            case .drum:
                return (.drum, 5.0)
            case .heading:
                return (.heading, Double(headingSecs))
            case .off:
                return (.none, 0.0)
            }
        }
        else {
            return (feedbackDirection == .port ? .low : .high, [0.0, 5.0, 2.5, 1.0][min(feedbackUrgency, 3)])
        }
    }
    
    private func updateAudioFeedback() {
        let (nextFeedbackSound, nextFeedbackInterval) = nextSoundAndInterval()
        if nextFeedbackSound == feedbackSound && nextFeedbackInterval == feedbackInterval {
            logger.debug("interval and sound are unchanged")
            return
        }
        let lastFeedbackInterval = feedbackInterval
        feedbackSound = nextFeedbackSound
        feedbackInterval = nextFeedbackInterval
        logger.debug("updated audio feedback, sound \(self.feedbackSound.rawValue), interval \(self.feedbackInterval)")
        
        if !audioFeedbackOn {
            // just return, updateAudioFeedback will be called again when audio feedback is turned on
            return
        }
        
        guard let audioTimer else {
            logger.debug("No current timer, playing sound immediately then creating timer")
            playAudioFeedbackSound()
            createTimer()
            return
        }
        
        // audioTimer must not be nil, so grab its fireDate and invalidate it
        let nowDate = Date()
        let fireDate = audioTimer.fireDate
        audioTimer.invalidate()
        
        if fireDate <= nowDate {
            logger.debug("fireDate is in past, playing immediately then creating timer")
            playAudioFeedbackSound()
            createTimer()
            return
        }
        
        // The scheduled timer firing date is in the future
        // The user is expecting feedback on a rhythm, try to meet that expectation when we change feedback.
        let remainingInterval = DateInterval(start: nowDate, end: fireDate).duration
        let consumedInterval = lastFeedbackInterval - remainingInterval
        logger.debug("A timer exists: \(consumedInterval) consumed, \(remainingInterval) remaining")
        if feedbackInterval <= consumedInterval {
            // The new feedback interval is less than the time already consumed in the past interval, so fire immediately
            // Imagine we have 1 second left on a 5 second interval Iso 4 seconds consumed), and the new interval is 2 seconds.  We don't want to wait that extra second
            logger.debug("feedbackInterval < consumedInterval, playing immediately then creating timer")
            playAudioFeedbackSound()
            createTimer()
        }
        else {
            // The new feedback interval is longer than the time already consumed.  We want to reset the timer's firing date so that we experience no shortening,
            // but we also don't wait the whole of the last interval.  Imagine we were in a 15 second interval, and only 1 second is consumed, and the new interval is 2 seconds
            // in that scenario we want to wait an additional second then play the new sound
            let newDelay = self.feedbackInterval - consumedInterval
            logger.debug("feedbackInterval > consumedInterval, creating timer to wait \(newDelay) seconds, then play sound and schedule timer")
            self.audioTimer = Timer.scheduledTimer(withTimeInterval: newDelay,
                                                   repeats: false)   { _ in
                                                                       self.playAudioFeedbackSound()
                                                                       self.createTimer()
                                                                       }
        }
    }
    
    @objc private func playAudioFeedbackSound() {
        //logger.debug("playAudioFeedbackSound called, audioFeedbackOn is \(self.audioFeedbackOn.description), sound is \(self.feedbackSound.rawValue)")
        switch feedbackSound {
        case .none:
            break
        case .drum:
            AudioServicesPlaySystemSound(self.sndNeutral)
        case .high:
            AudioServicesPlaySystemSound(self.sndHigh)
        case .low:
            AudioServicesPlaySystemSound(self.sndLow)
        case .heading:
            if self.sndHeading != nil {
                self.speechSynthesiser.speak(self.sndHeading!)
            }
        }
    }
}
