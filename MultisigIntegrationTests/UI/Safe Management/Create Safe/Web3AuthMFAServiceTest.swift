//
//  Web3AuthMFAServiceTest.swift
//  MultisigTests
//
//  Created by Dirk Jäckel on 09.08.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import XCTest
import tkey_pkg
@testable import Multisig

class Web3AuthMFAServiceTests: XCTestCase {

    var web2authMFAService: Web3AuthMFAService!
    var keychain: TestKeychainService!
    let aDeviceShare = "66665182a2b416cfe448413513dfc6ee8d87538b8d678bde30177c1f463aa822"
    let passwordShare = "4b5a18ed39e4b369fdcda96bdeeb7ec7375b3cdb89b5fb37de8635c8e07382d7"
    let postBoxKey = "c57c57f1a3463f14fb6ce79835f5df8437a8d449b5e2219aa2bb3876554f99cb"
    let publicAddress = "0x875b5EAAC06a857d1046cdA1b2a6683deeFbA5B4"
    let password = "foobar23"
    let finalKey = "75907aad04675827696b92ca481c6b00a24514d8b8819c97840c1960a50f7126"

    override func setUp() async throws {
        keychain = TestKeychainService()
    }

    override func tearDown() {
    }

    func testInitWithDeviceShare() async throws {
        // init with device share
        keychain.dict["\(publicAddress):device-key"] = Data(aDeviceShare.utf8)
        try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                          publicAddress: publicAddress,
                                                          keychainService: keychain)
        try await web2authMFAService.reconstruct()
        XCTAssert(web2authMFAService.finalKey == finalKey)
    }

    func testInitWithWrongDeviceShare() async throws {
        do {
            // init with wrong device share
            keychain.dict["\(publicAddress):device-key"] = Data("66665182a2b416cfe448413513dfc6ee8d87538b8d678bde30177c1f4aaaaaaa".utf8)
            try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                              publicAddress: publicAddress,
                                                              keychainService: keychain)
            try await web2authMFAService.reconstruct()
        } catch {
            XCTAssertEqual((error as? GSError.Web3AuthKeyReconstructionError)?.reason, GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to input device share").reason)
            XCTAssert(web2authMFAService.finalKey == nil)
        }
    }

    func testInitWithPassword() async throws {
        // no device share. use password
        try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                          publicAddress: publicAddress,
                                                          password: password,
                                                          keychainService: keychain)
        try await web2authMFAService.reconstruct()
        XCTAssert(web2authMFAService.finalKey == finalKey)
    }

    func testInitWithWrongPassword() async throws {
        // no device share. use wrong password
        do {

            try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                              publicAddress: publicAddress,
                                                              password: password,
                                                              keychainService: keychain)
            try await web2authMFAService.reconstruct()
        } catch {
            XCTAssertEqual((error as? GSError.Web3AuthKeyReconstructionError)?.reason, GSError.Web3AuthKeyReconstructionError(underlyingError: "password incorrect").reason)
            XCTAssert(web2authMFAService.finalKey == nil)
        }
    }

    func testRecreateDeviceShareWithPassword() async throws {
        do {
            try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                              publicAddress: publicAddress,
                                                              keychainService: keychain)
            try await web2authMFAService.reconstruct()

        } catch {
            try await web2authMFAService.recreateDeviceShare(password: password)
            try await web2authMFAService.reconstruct()

            // use saved share to reconstruct the finalKey
            let newKeyChain = TestKeychainService()
            try await newKeyChain.save(data: keychain.dict["\(publicAddress):device-key"]!, forKey: "\(publicAddress):device-key")
            try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                              publicAddress: publicAddress,
                                                              keychainService: newKeyChain)
            try await web2authMFAService.reconstruct()
            XCTAssert(web2authMFAService.finalKey == finalKey)
        }
    }

    func testRecreateDeviceShareWithWrongPassword() async throws {

        do {
            try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                              publicAddress: publicAddress,
                                                              keychainService: keychain)
            try await web2authMFAService.reconstruct()
        } catch {
            do {
                try await web2authMFAService.recreateDeviceShare(password: "foobar42")
                try await web2authMFAService.reconstruct()
            } catch {
                XCTAssertEqual((error as? GSError.Web3AuthKeyReconstructionError)?.reason, GSError.Web3AuthKeyReconstructionError(underlyingError: "password incorrect").reason)
                XCTAssert(web2authMFAService.finalKey == nil)
            }
        }
    }

    func testChangePasswordAfterReconstructWithDeviceShare() async throws {
        keychain.dict["\(publicAddress):device-key"] = Data(aDeviceShare.utf8)
        try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                          publicAddress: publicAddress,
                                                          keychainService: keychain)
        try await web2authMFAService.reconstruct()

        try await web2authMFAService.changePassword(oldPassword: password, newPassword: "foobar42")
        try await web2authMFAService.changePassword(oldPassword: "foobar42", newPassword: password)

    }

    func testChangePasswordAfterReconstructWithPassword() async throws {
        try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                          publicAddress: publicAddress,
                                                          password: password,
                                                          keychainService: keychain
        )
        try await web2authMFAService.reconstruct()

        try await web2authMFAService.changePassword(oldPassword: password, newPassword: "foobar42")
        try await web2authMFAService.changePassword(oldPassword: "foobar42", newPassword: password)
    }

    func testChangePasswordWithWrongPassword() async throws {
        keychain.dict["\(publicAddress):device-key"] = Data(aDeviceShare.utf8)
        try await web2authMFAService = Web3AuthMFAService(postBoxKey: postBoxKey,
                                                          publicAddress: publicAddress,
                                                          keychainService: keychain)
        try await web2authMFAService.reconstruct()

        do {
            try await web2authMFAService.changePassword(oldPassword: "foobar44", newPassword: "foobar42")
        } catch {
            XCTAssertEqual((error as? GSError.Web3AuthKeyReconstructionError)?.reason, GSError.Web3AuthKeyReconstructionError(underlyingError: "Old password incorrect").reason)
        }
    }
}

class TestKeychainService: SecureStore {
    var dict: [String: Data] = [:]

    func save(data: Data, forKey: String) throws {
        dict[forKey] = data
    }

    func data(forKey: String) throws -> Data? {
        if let result = dict[forKey] {
            return result
        }
        return nil
    }

    func allKeys() throws -> [String] {
        fatalError("allKeys() has not been implemented")
    }

    func removeData(forKey: String) throws {
    }

    func destroy() throws {
    }
}
