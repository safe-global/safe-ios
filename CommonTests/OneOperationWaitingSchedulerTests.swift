//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Common
import CommonTestSupport

class OneOperationWaitingSchedulerTests: XCTestCase {

    let interval: TimeInterval = 0.1
    var scheduler: OneOperationWaitingScheduler!

    var toggle = false
    var on: () -> Void {
        return { [unowned self] in
            self.toggle = true
        }
    }
    var off: () -> Void {
        return { [unowned self] in
            self.toggle = false
        }
    }

    override func setUp() {
        super.setUp()
        scheduler = OneOperationWaitingScheduler(interval: interval)
    }

    func test_whenAddingOneOperation_thenExecutesItImmediately() {
        scheduler.schedule(on)
        delay(interval / 10)
        XCTAssertTrue(toggle)
    }

    func test_whenAddingSecondOperationInWaitingPeriod_thenExecutesItAfterDelay() {
        scheduler.schedule(on)
        delay(interval * 0.5)
        scheduler.schedule(off)
        XCTAssertTrue(toggle)
        delay(interval * 0.6)
        XCTAssertFalse(toggle)
    }

    func test_whenAddingSecondOperationAfterWaitingPeriod_thenExecutesItImmediately() {
        scheduler.schedule(on)
        delay(interval)
        scheduler.schedule(off)
        delay(interval / 10)
        XCTAssertFalse(toggle)
    }

    func test_whenAddingManyOperationInWaitingPeriod_thenTakesOnlyFirst() {
        scheduler.schedule(on)
        delay(interval / 2)
        scheduler.schedule(off)
        scheduler.schedule(on)
        scheduler.schedule(on)
        delay(3 * interval)
        XCTAssertFalse(toggle)
    }

}
