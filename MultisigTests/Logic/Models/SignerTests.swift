//
//  SignerTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 25.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import SafeWeb3

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
            let pubKey = try EthereumPublicKey(message: message.makeBytes(),
                                               v: EthereumQuantity(quantity: BigUInt(signature.v - 27)),
                                               r: EthereumQuantity(signature.r.makeBytes()),
                                               s: EthereumQuantity(signature.s.makeBytes()))
            XCTAssertEqual(pubKey.address.hex(eip55: true), expectedSigner)
        } catch {
            XCTFail("error: \(error)")
        }
    }

    func testRecoverLedgerSignature() throws {
        let messageHash: Data = Data(hex: "ad9eb178b63d1b85f2721af8b4ec88e9a3acd5d00fc351d44d30ecffd3f20358")
        let v = BigUInt("1f", radix: 16)! - 4 // 4 is added so that the Safe contracts can decode this signature as eth_sign signature
        let r: Data = Data(hex: "2a442f1e65dfb418acf71ae06c4d84680a6ff377d7e7e0e68c4b8351dd6b833a")
        let s: Data = Data(hex: "7d03af4a99a8de94d2c45893a8fe07b4f37b46d6d9f8fd3af0d3a6c3da81e5b5")

        let prefixedMessageHash = "\u{19}Ethereum Signed Message:\n\(messageHash.count)"

        XCTAssertEqual(messageHash.count, 32)
        XCTAssertEqual(v, 27)

        let prefixedMessage = prefixedMessageHash.data(using: .utf8)! + messageHash

        let pubKey = try EthereumPublicKey(
            message: prefixedMessage.makeBytes(),
            v: EthereumQuantity(quantity: v - 27),
            r: EthereumQuantity(r.makeBytes()),
            s: EthereumQuantity(s.makeBytes()))

        XCTAssertEqual(pubKey.address.hex(eip55: true), "0xe44F9E113Fbd671Bf697d5a1cf1716E1a8c3F35b")
    }
}


