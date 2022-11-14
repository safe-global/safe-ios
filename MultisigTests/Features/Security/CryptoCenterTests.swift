//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

public class CryptoCenterTests: XCTestCase {

    var cryptoCenter: CryptoCenter! = nil
    var keychainCenter: KeychainCenter! = nil

    public override func setUp() {
        super.setUp()
        // Given
        keychainCenter = KeychainCenter()
        cryptoCenter = CryptoCenterImpl(keychainCenter)
    }

    func testInitialSetup() {
        print("testing initialSetup()")
        do {
            // When
            try cryptoCenter.initialSetup()
            cryptoCenter.import(privateKey: "0xF000")

            // then
            // Check kc


        } catch {
            // log errors
            LogService.shared.error(" --> initialSetup: \(error)")
            XCTFail()
        }

    }
}
