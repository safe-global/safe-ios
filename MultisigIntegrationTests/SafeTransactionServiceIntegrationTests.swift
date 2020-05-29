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

    func test_safeInfo_whenSendingNotASafe_returns404Error() {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                _ = try self.service.safeInfo(at: "0xc778417E063141139Fce010982780140Aa0cD5Ab")
            } catch {
                guard case HTTPClient.Error.entityNotFound(_, _, _) = error else {
                    XCTFail("Wrong error type")
                    return
                }
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    func test_safeInfo_whenSendingNotNormalizedAddress_returns422Error() {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                _ = try self.service.safeInfo(at: "0x728cafe9fb8cc2218fb12a9a2d9335193caa07e0")
            } catch {
                guard case HTTPClient.Error.unprocessableEntity(_, _, _) = error else {
                    XCTFail("Wrong error type")
                    return
                }
            }
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
