//
//  SafeRelayServiceTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 17.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class SafeTransactionServiceIntegrationTests: XCTestCase {
    var service = SafeTransactionService(url: URL(string: "https://safe-transaction.rinkeby.gnosis.io")!, logger: MockLogger())

    func testSafeInfo() {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            let result = try? self.service.safeInfo(at: "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
            XCTAssertEqual(result?.masterCopy, "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F")
            semaphore.signal()
        }
        semaphore.wait()
    }

    func testBalances() {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            let result = try? self.service.safeBalances(at: "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
            XCTAssertTrue(result?.count ?? 0 > 0)
            semaphore.signal()
        }
        semaphore.wait()
    }
}
