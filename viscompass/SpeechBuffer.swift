//
//  SpeechBuffer.swift
//  viscompass2
//
//  Created by Matt Clark on 3/9/2023.
//

import Foundation
import AVFoundation

class SpeechBuffer {
    private let wavBuffer: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: 1000000, alignment: 1)  // preallocate a megabyte of memory for the generated speech
    private var byteIndex: Int = 0
    
    var ready: Bool = false
    
    func clear() {
        ready = false
        byteIndex = 44 // length of WAV header that will get inserted later
    }
    
    func finalise() {
        storeWAVHeader()
        ready = true
    }
    
    func receive(buffer: AVAudioBuffer) {
        let pcmBuffer = buffer as! AVAudioPCMBuffer
        if pcmBuffer.frameLength == 0 {
            finalise()
        }
        else {
            if byteIndex + Int(pcmBuffer.frameLength) * 2 >= 1000000 {
                logger.debug("wav buffer is full, returning without adding samples")
                return
            }
            let newPtr = (wavBuffer + byteIndex).initializeMemory(as: Int16.self, repeating: 0, count: Int(pcmBuffer.frameLength))
            newPtr.update(from: pcmBuffer.int16ChannelData!.pointee, count: Int(pcmBuffer.frameLength))
            byteIndex += Int(pcmBuffer.frameLength) * 2
        }
    }
    
    func asData() -> Data {
        return Data(bytes: wavBuffer, count: byteIndex)
    }
    
    func storeStr(s: String, at: Int) {
        for (o, b) in Array(s.utf8).enumerated() {
            wavBuffer.storeBytes(of: b, toByteOffset: at + o, as: UInt8.self)
        }
    }
    
    func storeWAVHeader() {
        storeStr(s: "RIFF", at: 0) // RIFF header start
        wavBuffer.storeBytes(of: UInt32(byteIndex).littleEndian, toByteOffset: 4, as: UInt32.self) // total file length
        storeStr(s: "WAVE", at: 8) // RIFF header start
        storeStr(s: "fmt ", at: 12) // start of fmt chunk
        wavBuffer.storeBytes(of: UInt32(16).littleEndian, toByteOffset: 16, as: UInt32.self) // format header length
        wavBuffer.storeBytes(of: UInt16(1).littleEndian, toByteOffset: 20, as: UInt16.self) // file type (1=PCM)
        wavBuffer.storeBytes(of: UInt16(1).littleEndian, toByteOffset: 22, as: UInt16.self) // channel count
        wavBuffer.storeBytes(of: UInt32(22000).littleEndian, toByteOffset: 24, as: UInt32.self) // sample rate
        wavBuffer.storeBytes(of: UInt32(44000).littleEndian, toByteOffset: 28, as: UInt32.self) // byte rate
        wavBuffer.storeBytes(of: UInt16(2).littleEndian, toByteOffset: 32, as: UInt16.self) // block alignment
        wavBuffer.storeBytes(of: UInt16(16).littleEndian, toByteOffset: 34, as: UInt16.self) // bits per sample
        storeStr(s: "data", at: 36)  // start of data chunk
        wavBuffer.storeBytes(of: UInt32(byteIndex - 44).littleEndian, toByteOffset: 40, as: UInt32.self) // sample data length
    }
}
