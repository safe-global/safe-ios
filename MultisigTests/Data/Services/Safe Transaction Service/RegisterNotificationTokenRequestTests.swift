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

        // test vector from requirements doc
        try! mockStore.save(data: privateKey(for: "display bless asset brother fish sauce lyrics grit friend online tumble useless"),
                            forKey: KeychainKey.ownerPrivateKey.rawValue)
        let request1 = try RegisterNotificationTokenRequest(
            deviceID: UUID(uuidString: "33971c4e-fb98-4e18-a08d-13c881ae292a")!,
            safes: [Address("0x4dEBDD6CEe25b2F931D2FE265D70e1a533B02453"), Address("0x72ac1760daF52986421b1552BdCa04707E78950e")],
            token: "dSh5Se1XgEiTiY-4cv1ixY:APA91bG3vYjy9VgB3X3u5EsBphJABchb8Xgg2cOSSekPsxDsfE5xyBeu6gKY0wNhbJHgQUQQGocrHx0Shbx6JMFx2VOyhJx079AduN01NWD1-WjQerY5s3l-cLnHoNNn8fJfARqSUb3G",
            bundle: "io.gnosis.multisig.prod.mainnet",
            version: "2.7.0",
            buildNumber: "199",
            timestamp: "1605186645155")
        XCTAssertEqual(request1.signatures, ["671edd513d60363612071af9fb08f2414ab6984c3a669b0f29a6f9c885620b626814d1383731dc0fa985e86bd52e1cb6c3adcd75ff806856ece24f65d56d628d1c"])
    }

    private func privateKey(for mnemonic: String) -> Data {
        let mnemonic = "display bless asset brother fish sauce lyrics grit friend online tumble useless"
        let seedData = BIP39.seedFromMmemonics(mnemonic)!
        let rootNode = HDNode(seed: seedData)!.derive(path: HDNode.defaultPathMetamaskPrefix,
                                                      derivePrivateKey: true)!
        return rootNode.derive(index: 0, derivePrivateKey: true)!.privateKey!
    }
}
