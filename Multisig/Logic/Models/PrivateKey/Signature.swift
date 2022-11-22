//
//  Signature.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

// ecdsa secp256k1 signature
struct ECSecp256k1Signature {
    var r: UInt256
    var s: UInt256
}

// signature that can recover public key if message provided
struct ECSecp256k1ExtendedSignature {
    var r: UInt256
    var s: UInt256
    var v: UInt8 // recid: 0,1,2,3
}

// CRYPTO - ETHEREUM BOUNDARY

//  encodes secp256k1 signature
struct EthereumLegacySignature {
    var r: UInt256
    var s: UInt256
    // adds 27 to recid = {0,1,2,3}
    // why 27? Ethereum took it from Bitcoin. Wait, but why 27 in bitcion?
        // https://bitcoin.stackexchange.com/a/38909
        // https://bitcoin.stackexchange.com/questions/41359/are-there-any-signatures-where-the-recid-v-is-equal-to-29-30-or-33-34-compres
        // https://github.com/planetbeing/bitcoin-encrypt/blob/ddaf23d2ec3df761233698ff8060f508964b5c0e/bitcoin-encrypt.py#L196
        // https://bitcoin.stackexchange.com/questions/5082/why-do-compact-signatures-need-to-start-with-a-byte-27-35
        // https://github.com/bitcoin/bitcoin/blob/eb49457ff279721cc3cef10fe68fd75b4aa71833/src/key.cpp#L333
    var v: UInt8
}

// eip-155 ethereum signature (replay protected signature) for signing transactions with eip-155 hashing process
// https://eips.ethereum.org/EIPS/eip-155
// encodes secp256k1 signature
struct EthereumProtectedSignature {
    var r: UInt256
    var s: UInt256
    // eip-155 adds replay protection by encoding chainId into V: {0,1} + chainId * 2 + 35
    // chain ids can be > 109,
    // thus the resulting value will overflow the 1 byte.
    //
    // chain list represents chainId as Long (signed 64-bit integer)
    // https://github.com/ethereum-lists/chains/blob/a7cd0b68712dd4ef960353c111f182c64993719d/processor/src/main/kotlin/org/ethereum/lists/chains/Main.kt#L449
    //
    // So, the V here is 64 bit width.
    //
    // still, supports the legacy scheme with adding 27 or 28
    var v: Int64
}
