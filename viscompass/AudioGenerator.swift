//
//  AudioGenerator.swift
//  viscompass2
//
//  Created by Matt Clark on 4/9/2023.
//

import Foundation
import AVFoundation


// This class is responsible for actually making sounds
class AudioGenerator {
    private let speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    private var sndHigh: AVAudioPlayer?
    private var sndLow: AVAudioPlayer?
    private var sndNeutral: AVAudioPlayer?
    
    var headingPhrase: String = ""
    
    init() {
        //super.init()
        // Retrieve the shared audio session.
        logger.debug("Configuring audio session")
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Set the audio session category and mode.
            try audioSession.setCategory(.playback, mode: .default)
            logger.debug("Set audio session to category .playback, mode .default")
            sndHigh = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "click_high.wav", ofType: nil)!))
            sndLow = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "click_low.wav", ofType: nil)!))
            sndNeutral = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "drum200.wav", ofType: nil)!))
            logger.debug("Loaded static sound files")
            
        } catch {
            logger.debug("Failed to set the audio session configuration")
        }
    }

    func deactivate() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        }
        catch {
            logger.debug("Failed to set the audio session inactive")
        }
    }
    
    func activate() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        }
        catch {
            logger.debug("Failed to set the audio session active")
        }
    }
    
    func playSound(kind: AudioFeedbackSound) {
        switch kind {
        case .none:
            break
        case .drum:
            sndNeutral?.play()
        case .high:
            sndHigh?.play()
        case .low:
            sndLow?.play()
        case .heading:
            let utterance = AVSpeechUtterance(string: headingPhrase)
            speechSynthesizer.speak(utterance)
        }
    }
    
}
