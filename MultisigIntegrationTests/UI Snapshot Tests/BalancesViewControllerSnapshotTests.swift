//
//  BalancesViewControllerSnapshotTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 14.07.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
import SnapshotTesting
@testable import Multisig

class BalancesViewControllerSnapshotTests: CoreDataTestCase {
    
    static let config = FirebaseConfig()
    
    override class func setUp() {
        config.setUp()
    }

    func test_happyCase() throws {
        // Set Up
        // stub response from API
        let response: SafeBalanceSummary = try json("chains_4_safes_0x1230B3d59858296A31053C1b8562Ecf89A2f888b_balances_usd.json")
        let apiStub = StubBalancesAPI(response)

        // balances screen requires a safe that is selected.
        let chain = try makeChain(id: "1")
        let _ = Safe.create(address: "0x0000000000000000000000000000000000000001",
                            version: "1.2.0",
                            name: "safe",
                            chain: chain,
                            selected: true)

        // balances screen shows 'import key banner' unless already shown or imported key
        AppSettings.importKeyBannerWasShown = true

        // balances screen shows 'passcode banner' unless already shown or has key and no passcode is set
        AppSettings.passcodeBannerDismissed = true

        let vc = BalancesViewController()
        vc.clientGatewayService = apiStub


        // Act - load data on screen
        createWindow(vc)


        // Verify
        assertSnapshot(matching: vc, as: .image(size: CGSize(width: 375, height: 750)))
    }
}

class StubBalancesAPI: BalancesAPI {
    let result: SafeBalanceSummary

    init(_ result: SafeBalanceSummary) {
        self.result = result
    }

    func asyncBalances(safeAddress: Address,
                       chainId: String,
                       completion: @escaping (Result<SafeBalanceSummary, Error>) -> Void) -> URLSessionTask? {
        completion(.success(result))
        return nil
    }
}
