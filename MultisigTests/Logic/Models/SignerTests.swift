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
    let mockStore = MockSecureStore()

    override func setUpWithError() throws {
        super.setUp()
        App.shared.keychainService = mockStore
        try! mockStore.save(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"),
                            forKey: KeychainKey.ownerPrivateKey.rawValue)
    }

    func testSigner() throws {
        let string = "gnosis-safe"
        let expected = Signer.Signature(value: "0x99a7a03e9597e85a0cc4188d270b72b1df2de943de804f144976f4c1e23116ff274d2dec4ee7201b88bdadf08259a5dc8e7e2bbf372347de3470beeab904e5d01b",
                                        signer: "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0")
        XCTAssertEqual(try Signer.sign(string), expected)
    }
}
