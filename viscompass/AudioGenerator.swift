//
//  AudioGenerator.swift
//  viscompass2
//
//  Created by Matt Clark on 4/9/2023.
//

import Foundation
import AVFoundation

// This class is responsible for actually making sounds
class AudioGenerator: NSObject, AVSpeechSynthesizerDelegate {
    private let speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    
    private var sndHigh: AVAudioPlayer?
    private var sndLow: AVAudioPlayer?
    private var sndNeutral: AVAudioPlayer?
    private var sndHeading: AVAudioPlayer?
    
    private var headingPhrase: String = ""
    private var lastSpokenPhrase: String  = ""
    
    private var bufHeading: SpeechBuffer = SpeechBuffer()
    
    override init() {
        super.init()
        configureAudioSession()
        speechSynthesizer.delegate = self
    }
    
    
    func configureAudioSession() {
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
    
    func setHeadingPhrase(phrase: String) {
        headingPhrase = phrase
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
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        logger.debug("Finished speaking")
        do {
            sndHeading = try AVAudioPlayer(data: bufHeading.asData())
            sndHeading?.play()
        } catch let e {
            logger.debug("Failed to create heading audio player: \(e)")
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
            if headingPhrase != lastSpokenPhrase {
                let utterance = AVSpeechUtterance(string: headingPhrase)
                bufHeading.clear()
                speechSynthesizer.write(utterance, toBufferCallback: bufHeading.receive)
                lastSpokenPhrase = headingPhrase
                // this logic completes  asynchronously in the didFinish delegate of AVSpeechSynthesizer
                // because it takes a short time (<100ms) for the the speech to be generated and buffered
                // so this method will return, and when the speech is ready playHeading() will be called
            }
            else {
                // resuse the last played heading
                sndHeading?.play()
            }
        }
    }
    
}
