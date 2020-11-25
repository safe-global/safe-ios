//
//  SignerTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 25.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class SignerTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        App.shared.keychainService = MockSecureStore()
    }

    func testSigner() throws {
//        let string = "gnosis-safe33971c4e-fb98-4e18-a08d-13c881ae292a0x4dEBDD6CEe25b2F931D2FE265D70e1a533B024530x72ac1760daF52986421b1552BdCa04707E78950edSh5Se1XgEiTiY-4cv1ixY:APA91bG3vYjy9VgB3X3u5EsBphJABchb8Xgg2cOSSekPsxDsfE5xyBeu6gKY0wNhbJHgQUQQGocrHx0Shbx6JMFx2VOyhJx079AduN01NWD1-WjQerY5s3l-cLnHoNNn8fJfARqSUb3Gio.gnosis.multisig.prod.mainnet2.7.0IOS1991605186645155"
//        let expectedSignature = Signer.Signature(value: <#T##String#>, signer: <#T##String#>)
//        XCTAssertEqual(Signer.sign(string), <#T##expression2: Equatable##Equatable#>)
    }

}
