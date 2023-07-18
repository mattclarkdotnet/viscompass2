//
//  viscompassTests.swift
//  viscompassTests
//
//  Created by Matt Clark on 6/5/2023.
//

import XCTest
@testable import viscompass2

final class viscompassTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testNormaliseDegrees() throws {
        XCTAssertEqual(normaliseDegrees(degrees: 0.0), 0.0)
        XCTAssertEqual(normaliseDegrees(degrees: 360.0), 0.0)
        XCTAssertEqual(normaliseDegrees(degrees: -360.0), 0.0)
        XCTAssertEqual(normaliseDegrees(degrees: 10.0), 10.0)
        XCTAssertEqual(normaliseDegrees(degrees: 180.0), 180.0)
        XCTAssertEqual(normaliseDegrees(degrees: 190.0), 190.0)
        XCTAssertEqual(normaliseDegrees(degrees: 350.0), 350.0)
        XCTAssertEqual(normaliseDegrees(degrees: 370.0), 10.0)
        XCTAssertEqual(normaliseDegrees(degrees: 730.0), 10.0)
        XCTAssertEqual(normaliseDegrees(degrees: -10.0), 350.0)
        XCTAssertEqual(normaliseDegrees(degrees: -150.0), 210.0)
        XCTAssertEqual(normaliseDegrees(degrees: -510.0), 210.0)
    }


}
