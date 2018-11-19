//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Database

class FileSystemGuardTests: XCTestCase {

    let fsGuard = FileSystemGuard()
    let semaphore = DispatchSemaphore(value: 0)

    func test_whenUnlockNotificationComes_thenSignalsToSemaphore() {
        fsGuard.didLock()
        fsGuard.addUnlockSemaphore(semaphore)
        let exp = expectation(description: "wait")
        DispatchQueue.global().async {
            self.semaphore.wait()
            exp.fulfill()
        }
        fsGuard.didUnlock()
        waitForExpectations(timeout: 0.1)
    }

    func test_whenAlreadyUnlocked_thenSignalsImmediately() {
        fsGuard.addUnlockSemaphore(semaphore)
        self.semaphore.wait()
    }

}
