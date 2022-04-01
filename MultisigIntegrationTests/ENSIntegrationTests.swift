//
//  ENSIntegrationTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class ENSIntegrationTests: CoreDataTestCase {
    lazy var domainManager: BlockchainDomainManager = {
        let chain = Chain.mainnetChain()
        return BlockchainDomainManager(rpcURL: chain.authenticatedRpcUrl,
                                       chainId: chain.id!,
                                       ensRegistryAddress: AddressString(chain.ensRegistryAddress!))
    }()

    func test_forwardResolution() {
        XCTAssertNoThrow(try {
            let address = try domainManager.resolveEnsDomain(domain: "alice.eth")
            XCTAssertEqual(address, "0xcd2E72aEBe2A203b84f46DEEC948E6465dB51c75")
        }())
    }

    // the resolver is expired.
    func disabled_test_reverseResolution() {
        let name = domainManager.ensName(for: "0x2333b4CC1F89a0B4C43e9e733123C124aAE977EE")
        XCTAssertEqual(name, "gnosissafeios.test")
    }
}
