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
            deviceID: "bb30cd3e-e0ad-4e9a-b726-44db67a0820b",
            safes: [Address("0xEefFcdEAB4AC6005E90566B08EAda3994A573C1E")],
            token: "erXBYb-CxU1jtSvwfZrxqW:APA91bH0IWkMWOGizlbNAwxV6OVjEmNR1feRs2WBT7BE6aVMm2C-x1COKqNYq19t5YNjIzVBKDyVVEqFojlkvEtiSaJA0lCZL0LfuEwfc8p9jfBuM6HG82pczVbnMev1J0gXlB3bIlAP",
            bundle: "io.gnosis.multisig.dev.rinkeby",
            version: "2.6.0",
            buildNumber: "1",
            timestamp: "1606319110027")
        XCTAssertEqual(request.signatures, ["0x05a119049f1385fc1c8785389a7f7c7c1c104d54ce0225a856ca580c6085d45428d26bbf273b3fe5428a921a5fbc6658e024e87ac0a3291ba8015949c0e7945d1c"])

        // test vector from requirements doc
        try! mockStore.save(data: privateKey(for: "display bless asset brother fish sauce lyrics grit friend online tumble useless"),
                            forKey: KeychainKey.ownerPrivateKey.rawValue)
        let request1 = try RegisterNotificationTokenRequest(
            deviceID: "33971c4e-fb98-4e18-a08d-13c881ae292a",
            safes: [Address("0x72ac1760daF52986421b1552BdCa04707E78950e"), Address("0x4dEBDD6CEe25b2F931D2FE265D70e1a533B02453")],
            token: "dSh5Se1XgEiTiY-4cv1ixY:APA91bG3vYjy9VgB3X3u5EsBphJABchb8Xgg2cOSSekPsxDsfE5xyBeu6gKY0wNhbJHgQUQQGocrHx0Shbx6JMFx2VOyhJx079AduN01NWD1-WjQerY5s3l-cLnHoNNn8fJfARqSUb3G",
            bundle: "io.gnosis.multisig.prod.mainnet",
            version: "2.7.0",
            buildNumber: "199",
            timestamp: "1607013002")
        XCTAssertEqual(request1.signatures, ["0x77a687a3e0021202c4d542a6aeccdb0a22bdcb722892d3a5082334d2c72468771a1e7aa303925a0115a09789c36a2a1e7bb5feb212bbd4db7c9f0c1ab01739291b"])
    }

    private func privateKey(for mnemonic: String) -> Data {
        let seedData = BIP39.seedFromMmemonics(mnemonic)!
        let rootNode = HDNode(seed: seedData)!.derive(path: HDNode.defaultPathMetamaskPrefix,
                                                      derivePrivateKey: true)!
        return rootNode.derive(index: 0, derivePrivateKey: true)!.privateKey!
    }
}
