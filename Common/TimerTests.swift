//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Common

class TimerTests: XCTestCase {

    func test_random() {
        let avg = 1.0
        let dev = 0.5
        for _ in (0..<1_000) {
            let value = Timer.random(average: avg, maxDeviation: dev)
            XCTAssertLessThanOrEqual(value, avg + dev)
            XCTAssertGreaterThanOrEqual(value, avg - dev)
        }
    }

}
