//
//  SignerTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 25.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import Web3

class SignerTests: XCTestCase {
    func testSigner() throws {
        let key = try PrivateKey(data:  Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))
        let expectedSignature = "0x99a7a03e9597e85a0cc4188d270b72b1df2de943de804f144976f4c1e23116ff274d2dec4ee7201b88bdadf08259a5dc8e7e2bbf372347de3470beeab904e5d01b"
        let expectedSigner = "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0"
        let preimage = "gnosis-safe"
        let message = preimage.data(using: .utf8)!

        let hash = EthHasher.hash(message)
        let signature = try key.sign(hash: hash)

        XCTAssertEqual(signature.hexadecimal, expectedSignature)
        XCTAssertEqual(signature.signer, Address(exactly: expectedSigner))

        do {
            let pubKey = try EthereumPublicKey.init(message: message.makeBytes(),
                                                    v: EthereumQuantity(quantity: BigUInt(signature.v - 27)),
                                                    r: EthereumQuantity(signature.r.makeBytes()),
                                                    s: EthereumQuantity(signature.s.makeBytes()))
            XCTAssertEqual(pubKey.address.hex(eip55: true), expectedSigner)
        } catch {
            print("error: \(error)")
        }
    }
}
