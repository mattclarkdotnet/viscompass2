//
//  Util.swift
//  viscompass2
//
//  Created by Matt Clark on 14/5/2024.
//

import Foundation

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
