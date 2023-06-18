//
//  HeadingFilter.swift
//  viscompass2
//
//  Created by Matt Clark on 8/6/2023.
//

import Foundation

struct Reading {
    let value: Double
    let date: Date
}

func differenceDegrees(a: Double, b: Double) -> Double {
    let diffwith = a > 180 ? a - 360 : a
    let result = b - diffwith
    return result < 180 ? result : result - 360
}


struct SensitivitySetting {
    let cutoffSeconds: Double
    let cutoffSamples: Int
    let gamma: Double
}

let e = 2.718281
let factor_after_max_time: Double = 0.05
let time_resolution = 0.1
let max_time = 20.0
let max_samples = Int(max_time/time_resolution)


                  
class HeadingFilter {
    private var intermittent_readings: [Reading] = [] // from newest to oldest
    private var sensitivities: [SensitivitySetting] = []
    
    init () {
        for t in [max_time, max_time/2, max_time/4, max_time/8, max_time/16] {
            sensitivities.append(SensitivitySetting(cutoffSeconds: t,
                                                    cutoffSamples: Int(t / time_resolution),
                                                    gamma: pow(e, log(factor_after_max_time)/(t/time_resolution))))
        }
        logger.debug("Sensitivities: \(self.sensitivities)")
        
    }
    
    func add_reading(value: Double) {
        let now = Date()
        intermittent_readings.insert(Reading(value: value, date: now), at: 0)
        if intermittent_readings.count > 100 {
            // if we have 100 or more readings, discard those older than a minute
            let oneMinuteAgo = Date(timeIntervalSinceNow: -60)
            intermittent_readings.removeAll(where: { $0.date < oneMinuteAgo })
        }
    }
    
    private func regularised_to_now() -> [Double] {
        var regularised_values: [Double] = []
        let readings = [Reading(value: intermittent_readings.first!.value, date: Date())] + intermittent_readings
        for i  in (0 ..< readings.count - 1 ) {
            regularised_values.append(contentsOf: samples_between(mostRecent: readings[i], nextMostRecent: readings[i+1]))
            if regularised_values.count > max_samples {
                break
            }
        }
        return regularised_values
    }
    
    private func samples_between(mostRecent: Reading, nextMostRecent: Reading) -> [Double] {
        let secondsSinceLastReading = DateInterval(start: nextMostRecent.date, end: mostRecent.date).duration
        let samplesToAdd = Int(secondsSinceLastReading / time_resolution)
        return [mostRecent.value] + Array(repeating: nextMostRecent.value, count: samplesToAdd )
    }
    
    func filtered(sensitivityIndex: Int) -> Double {
        let sensitivity = sensitivities[sensitivityIndex]
        if intermittent_readings.count == 0 {
            return 123.0 // Magic number for UI debugging
        }
        else if intermittent_readings.count == 1 {
            return self.intermittent_readings.first!.value
        }
        // At this point we have at least two readings
        let vals = regularised_to_now()  // translate a set of intermittent readings to a regular set of readings with a certain time resolution
        let count = min(vals.count, sensitivity.cutoffSamples)
        var sum: Double = 0
        for i in 1..<count {
            let delta = differenceDegrees(a: vals[0], b: vals[i])
            let p = pow(sensitivity.gamma, Double(i))
            sum += delta * p // so when i is 0 and gamma is 0.5, exp(gamma, i) is 1, and when i is 4 and gamma is 0.5 exp(gamma, i) is 0.5^4 = 0.0625
        }
        let result = vals[0] + (sum / Double(count))
        return result > 0 ? result : 360 + result
    }
}
