//
//  HalfTests.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 6/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import XCTest
@testable import EgoEditor

class HalfTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testUIntToHalfFloat() {
        var number: UInt16 = 14766
 
        
        XCTAssertEqualWithAccuracy(f16toFloat(&number), 0.7099609, accuracy: 0.00001)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
