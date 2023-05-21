//
//  AudioFeedbackModel.swift
//  viscompass
//
//  Created by Matt Clark on 9/5/2023.
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
    case compass = "compass"
    case none = "none"
}

enum OnCourseFeedbackType: String {
    case drum = "drum"
    case heading = "heading"
    case off = "off"
}


class AudioFeedbackModel: ObservableObject {
    @Published var audioFeedbackOn: Bool = false
    
    private var onCourseFeedbackType: OnCourseFeedbackType = .drum // TODO: take from settings
    private var feedbackInterval: TimeInterval = 0
    private var feedbackSound: AudioFeedbackSound = .drum // TODO: take from settings
    private var feedbackHeading: Int = 0
    private var audioTimer: Timer?
    
    private let speechSynthesiser: AVSpeechSynthesizer = AVSpeechSynthesizer()
    private let sndHigh: SystemSoundID = createSound("click_high", fileExt: "wav")
    private let sndLow: SystemSoundID = createSound("click_low", fileExt: "wav")
    private let sndNeutral: SystemSoundID = createSound("drum200", fileExt: "wav")
    
    
    func toggleFeedback() {
        audioFeedbackOn.toggle()
        logger.debug("Toggled audio feedback, new is \(self.audioFeedbackOn)")
    }
    
    func setOnCourseFeedbackType(feedbacktype: OnCourseFeedbackType) {
        logger.debug("Setting on course feedback type to \(feedbacktype.rawValue)")
        onCourseFeedbackType = feedbacktype
    }
    
    func nextSoundAndInterval(urgency: Int, direction: Turn) -> (AudioFeedbackSound, TimeInterval) {
        if urgency == 0 {
            // we are within tolerance
            switch onCourseFeedbackType {
            case .drum:
                return (.drum, 5.0)
            case .heading:
                return (.heading, 12.0)
            case .off:
                return (.none, 0.0)
            }
        }
        else {
            return (direction == .port ? .low : .high, [0.0, 5.0, 2.5, 1.0][min(urgency, 3)])
        }
    }

    func updateAudioFeedback(urgency: Int, direction: Turn, heading: Double) {
        let lastFeedbackInterval = feedbackInterval
        (feedbackSound, feedbackInterval) = nextSoundAndInterval(urgency: urgency, direction: direction)
        logger.debug("updating audio feedback, sound \(self.feedbackSound.rawValue), interval \(self.feedbackInterval)")
        feedbackHeading = Int(heading)
        
        if audioTimer == nil {
            // No timer currently exists, so no sound is scheduled.  Call playAudioFeedbackSound which will play the sound now, and schedule the next timer
            // This _should_ be safe as everything is executing on the UI thread....
            logger.debug("No current timer")
            playAudioFeedbackSound()
        }
        else {
            // A timer already exists, so reuse it - the sound played will be determined by the new value we just put into feedbackSound
            // Imagine the compass heading was due to be read out in 10 seconds time, but we are off course and want to send a beep feedback in 1 second
            // Or imagine we were about to send an audio beep in 1 second, but we are on course now and want to send a heading update in 15 seconds
            let remainingInterval = DateInterval(start: Date(), end: audioTimer!.fireDate).duration
            let consumedInterval = lastFeedbackInterval - remainingInterval
            logger.debug("A timer exists: \(consumedInterval) consumed, \(remainingInterval) remaining")
            // The user is expecting feedback on a rhythm, try to meet that expectation when we change feedback.
            // This code could be contracted but it wuld become a lot harder to understand
            if feedbackInterval <= remainingInterval {
                // The new feedback interval must be less than the one before, as it is less than the remaining time in the current timer.direction
                // Imagine we were giving headings every 15 seconds, but now we are off course - we don't want to wait e.g. 12 seconds to give that feedback
                // So we might have a new interval of 2 seconds, whereas the old was 5 and there are 3 remaining
                // In this scenario we should play the new sound immediately
                logger.debug("feedbackInterval < remainingInterval, playing immediately")
                audioTimer!.invalidate()
                playAudioFeedbackSound()
            }
            else if feedbackInterval <= consumedInterval {
                // The new feedback interval is less than the time already consumed in the past interval, so fire immediately
                // Imagine we have 1 second left on a 5 second interval, and the new interval is 2 seconds.  We don't want to wait that extra second
                logger.debug("feedbackInterval < consumedInterval, playing immediately")
                audioTimer!.invalidate()
                playAudioFeedbackSound()
            }
            else {
                // The new feedback interval is longer than the time already consumed.  We want to reset the timer's firing date so that we experience no shortening,
                // but we also don't wait the whle of the ld interval.  IMagine we were n a 15 second interval, and only 1 second is consumed, and the new timer is 2 seconds
                // in that scenario we want to wait an additional second then play the new sound
                audioTimer!.fireDate = Date(timeIntervalSinceNow: feedbackInterval - consumedInterval)
                logger.debug("feedbackInterval > consumedInterval, adjusting timer, next fireDate is \(self.audioTimer!.fireDate)")
            }
        }
    }
    
    @objc func playAudioFeedbackSound() {
        // logger.debug("playAudioFeedbackSound called, sound is \(self.feedbackSound.rawValue)")
        if audioFeedbackOn {
            switch feedbackSound {
            case .none:
                logger.debug("No sound selected in playAudioFeedbackSound")
                break
            case .drum:
                AudioServicesPlaySystemSound(sndNeutral)
            case .high:
                AudioServicesPlaySystemSound(sndHigh)
            case .low:
                AudioServicesPlaySystemSound(sndLow)
            case .heading, .compass:
                let headingStr = feedbackHeading.description // e.g. '130'
                let headingDigits = headingStr.map({"\($0) "})
                let u = AVSpeechUtterance(string: "heading \(headingDigits)")
                speechSynthesiser.speak(u)
            }
        }
        if feedbackInterval > 0 {
            if audioTimer != nil {
                audioTimer?.invalidate()
            }
            audioTimer = Timer.scheduledTimer(timeInterval: feedbackInterval,
                                              target: self,
                                              selector: #selector(AudioFeedbackModel.playAudioFeedbackSound),
                                              userInfo: nil,
                                              repeats: false)
        }
    }
}
