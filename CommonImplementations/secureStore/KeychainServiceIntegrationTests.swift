//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import CommonImplementations
import Common

class KeychainServiceIntegrationTests: XCTestCase {

    let keychainService = KeychainService(identifier: "KeychainIntegrationTest")

    func test_whenCreated_thenCanBeDestroyed() throws {
        
    }

//    let correctPassword = "Password"
//    let encryptionService = EncryptionService()
//    var correctPrivateKey: PrivateKey!
//    var correctMnemonic: Mnemonic!

//    override func setUp() {
//        super.setUp()
//        correctMnemonic = encryptionService.generateMnemonic()
//        correctPrivateKey = encryptionService.derivePrivateKey(from: correctMnemonic)
//        do {
//            try keychainService.removePassword()
//            try keychainService.removeMnemonic()
//            try keychainService.removePrivateKey()
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }
//
//    // MARK: - Password
//
//    func test_password_whenNotSet_thenReturnsNil() {
//        do {
//            let password = try keychainService.password()
//            XCTAssertNil(password)
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }
//
//    func test_password_whenSaved_thenReturns() {
//        do {
//            try keychainService.savePassword(correctPassword)
//            let password = try keychainService.password()
//            XCTAssertEqual(password, correctPassword)
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }
//
//    func test_password_whenRemoved_thenReturnsNil() {
//        do {
//            try keychainService.savePassword(correctPassword)
//            try keychainService.removePassword()
//            let password = try keychainService.password()
//            XCTAssertNil(password)
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }
//
//    // MARK: - Private Key
//
//    func test_privateKey_whenNotSet_thenReturnsNil() {
//        do {
//            let privateKey = try keychainService.privateKey()
//            XCTAssertNil(privateKey)
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }
//
//    func test_privateKey_whenSaved_thenReturns() {
//        do {
//            try keychainService.savePrivateKey(correctPrivateKey)
//            let privateKey = try keychainService.privateKey()
//            XCTAssertEqual(privateKey, correctPrivateKey)
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }
//
//    func test_privateKey_whenRemoved_thenReturnsNil() {
//        do {
//            try keychainService.savePrivateKey(correctPrivateKey)
//            try keychainService.removePrivateKey()
//            let privateKey = try keychainService.privateKey()
//            XCTAssertNil(privateKey)
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }
//
//    // MARK: - Mnemonic
//
//    func test_mnemonic_whenNotSet_thenReturnsNil() {
//        do {
//            let mnemonic = try keychainService.mnemonic()
//            XCTAssertNil(mnemonic)
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }
//
//    func test_mnemonic_whenSaved_thenReturns() {
//        do {
//            try keychainService.saveMnemonic(correctMnemonic)
//            let mnemonic = try keychainService.mnemonic()
//            XCTAssertEqual(mnemonic, correctMnemonic)
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }
//
//    func test_mnemonic_whenRemoved_thenReturnsNil() {
//        do {
//            try keychainService.saveMnemonic(correctMnemonic)
//            try keychainService.removeMnemonic()
//            let mnemonic = try keychainService.mnemonic()
//            XCTAssertNil(mnemonic)
//        } catch let e {
//            XCTFail("Failed: \(e)")
//        }
//    }

}
