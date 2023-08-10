//
//  Web3AuthMFAServiceTest.swift
//  MultisigTests
//
//  Created by Dirk Jäckel on 09.08.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class Web3AuthMFAServiceTests: XCTestCase {

    var web2authMFAService: Web3AuthMFAService!
    var keychain: TestKeychainInterface!

    override func setUp() async throws {
        keychain = TestKeychainInterface()
    }

    func testInitWithDeviceShare() async throws {
        // init with device share
        keychain.dict["0x875b5EAAC06a857d1046cdA1b2a6683deeFbA5B4:device-key"] = "66665182a2b416cfe448413513dfc6ee8d87538b8d678bde30177c1f463aa822"
        try await web2authMFAService = Web3AuthMFAService(postBoxKey: "c57c57f1a3463f14fb6ce79835f5df8437a8d449b5e2219aa2bb3876554f99cb",
                                                          publicAddress: "0x875b5EAAC06a857d1046cdA1b2a6683deeFbA5B4",
                                                          keychainInterface: keychain)
        try await web2authMFAService.reconstruct()
        XCTAssert(web2authMFAService.finalKey == "75907aad04675827696b92ca481c6b00a24514d8b8819c97840c1960a50f7126")

    }

    func testInitWithPassword() async throws {
        // no device share. use password
        try await web2authMFAService = Web3AuthMFAService(postBoxKey: "c57c57f1a3463f14fb6ce79835f5df8437a8d449b5e2219aa2bb3876554f99cb",
                                                          publicAddress: "0x875b5EAAC06a857d1046cdA1b2a6683deeFbA5B4",
                                                          password: "foobar23",
                                                          keychainInterface: keychain)
        try await web2authMFAService.reconstruct()
        XCTAssert(web2authMFAService.finalKey == "75907aad04675827696b92ca481c6b00a24514d8b8819c97840c1960a50f7126")
    }
}

class TestKeychainInterface: KeychainInterface {

    var dict: [String:String] = [:]

    func save(item: String, key: String) throws {
        dict[key] = item
    }
    func fetch(key: String) throws -> String {
        if let result = dict[key] {
            return result
        }
        throw KeychainError.itemNotFound
    }
}
