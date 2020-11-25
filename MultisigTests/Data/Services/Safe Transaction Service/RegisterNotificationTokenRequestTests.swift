//
//  RegisterNotificationTokenRequestTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 25.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class RegisterNotificationTokenRequestTests: XCTestCase {
    let mockStore = MockSecureStore()

    override func setUpWithError() throws {
        App.shared.keychainService = mockStore
        try! mockStore.save(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"),
                            forKey: KeychainKey.ownerPrivateKey.rawValue)
    }


    func testRequestInitCalculatesProperSignature() throws {
        let request = try RegisterNotificationTokenRequest(
            deviceID: UUID(uuidString: "bb30cd3e-e0ad-4e9a-b726-44db67a0820b")!,
            safes: [Address("0xEefFcdEAB4AC6005E90566B08EAda3994A573C1E")],
            token: "erXBYb-CxU1jtSvwfZrxqW:APA91bH0IWkMWOGizlbNAwxV6OVjEmNR1feRs2WBT7BE6aVMm2C-x1COKqNYq19t5YNjIzVBKDyVVEqFojlkvEtiSaJA0lCZL0LfuEwfc8p9jfBuM6HG82pczVbnMev1J0gXlB3bIlAP",
            bundle: "io.gnosis.multisig.dev.rinkeby",
            version: "2.6.0",
            buildNumber: "1",
            timestamp: "1606319110027")
        XCTAssertEqual(request.signatures, ["460ab62322407376576be061a6bfaaaa78cd1be4e0421d88cd635d0568ff2d473280d0edfd898bf1fd73f3fea8206ef91d6fbf6d9dc63b5d7d1378b8e4059f691c"])
    }
}
