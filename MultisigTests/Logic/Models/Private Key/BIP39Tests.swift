//
//  MnemonicTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 07.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import CryptoSwift
import SafeWeb3

class BIP39Tests: XCTestCase {
    func testMnemonics() throws {
        let testData = [
            (mnemonic: "talent amateur nation duty virtual vanish broken piano ignore clock dash merit",
             seed: "692e25c4924aa3f6a03791c447a48e78f0752ab4a04a3eaadeb5370da07666c971a5eb4f7313493f22dc5480a4ca85284c5280562867ef4105b7d46fe27162b1",
             address0: "0xD1C8B55434c67C7c255d3aF19309D2f7A70A495C",
             address1: "0x620379cF1d87F114461Ca9018746cA7254a0eEB8"),

            (mnemonic: "saddle this exist slam call reward patient scale network ceiling stuff wild tower tourist insane weapon inform neck identify naive trip nut usual ticket",
            seed: "ee51f8836ed253e58c4679755fbc0bd8541651a98df1b92c972f3bfd7fa9f5cb487438a1b57ca4782b371920793a13aabd4fd7ae91f8bd7e17047f64e7a91871",
            address0: "0xD3F042a9EaeC31a126e609852A2626b64f6EABD9",
            address1: "0xf2a49fBa9cfD13E22e2a13bB3Ae6a24eD1D948b5"),
        ]

        for data in testData {
            let seed = BIP39.seedFromMmemonics(data.mnemonic)!
            XCTAssertEqual(seed, Data(hex: data.seed))

            let rootNode = HDNode(seed: seed)!.derive(path: HDNode.defaultPathMetamaskPrefix, derivePrivateKey: true)!

            let at0 = rootNode.derive(index: 0, derivePrivateKey: true)!
            let pk0 = try EthereumPrivateKey(hexPrivateKey: at0.privateKey!.toHexString())
            XCTAssertEqual(pk0.address.hex(eip55: true), data.address0)

            let at1 = rootNode.derive(index: 1, derivePrivateKey: true)!
            let pk1 = try EthereumPrivateKey(hexPrivateKey: at1.privateKey!.toHexString())
            XCTAssertEqual(pk1.address.hex(eip55: true), data.address1)
        }
    }

    // https://github.com/matter-labs/web3swift/blob/develop/Tests/web3swiftTests/web3swift_keystores_Tests.swift

    func testBIP39 () {
        var entropy: Data = Data(hex: "00000000000000000000000000000000")
        var phrase = BIP39.generateMnemonicsFromEntropy(entropy: entropy)
        XCTAssert( phrase == "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")
        var seed = BIP39.seedFromMmemonics(phrase!, password: "TREZOR")
        XCTAssert(seed?.toHexString() == "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04")
        entropy = Data(hex: "68a79eaca2324873eacc50cb9c6eca8cc68ea5d936f98787c60c7ebc74e6ce7c")
        phrase = BIP39.generateMnemonicsFromEntropy(entropy: entropy)
        XCTAssert( phrase == "hamster diagram private dutch cause delay private meat slide toddler razor book happy fancy gospel tennis maple dilemma loan word shrug inflict delay length")
        seed = BIP39.seedFromMmemonics(phrase!, password: "TREZOR")
        XCTAssert(seed?.toHexString() == "64c87cde7e12ecf6704ab95bb1408bef047c22db4cc7491c4271d170a1b213d20b385bc1588d9c7b38f1b39d415665b8a9030c9ec653d75e65f847d8fc1fc440")
    }

    func testBIP39SeedAndMnemConversions() {
        let seed = Data.randomBytes(length: 32)!
        let mnemonics = BIP39.generateMnemonicsFromEntropy(entropy: seed)
        let recoveredSeed = BIP39.mnemonicsToEntropy(mnemonics!, language: .english)
        XCTAssert(seed == recoveredSeed)
    }
}
