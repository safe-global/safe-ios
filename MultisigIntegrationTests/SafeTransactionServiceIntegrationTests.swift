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
    var service = SafeTransactionService(url: URL(string: "https://safe-relay.rinkeby.gnosis.io")!, logger: MockLogger())

    func testSafeInfo() throws {
        let result = try service.safeInfo(at: "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(result.masterCopy, "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F")
    }
}
