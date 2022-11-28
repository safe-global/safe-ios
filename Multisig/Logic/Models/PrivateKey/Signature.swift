//
//  Signature.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

// Cryptographic Elliptic Curve secp256k1 digital signature algorithm context

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
//
// TODO: question is whether a signature with overflown byte is accepted by the network if its chain_id is > 109? signature length will be bigger than 65 bytes! Or we just cut it off?
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

    var chainId: Int64
}

// Signature Algorithms
// - ecdsa secp256k1 - crypto
// eth signature algorithms
// - eth_sign
// - personal_sign ??
// - signTypedData_vX (1, 2, 3, 4) ??
// safe signature algorithms
// - pre-validated: approveHash() executed before OR message sender is an owner
// - safe contract signature encoding

// Verification Algorithms
// - ecrecover (ecdsa signature, hash) -> public key -> address
// - eth_sign verification
// - personal_sign verification
// - signTypedData_vX verification
// - eip 1271 contract signature validation
// - approveHash | message sedner is owner verification

// Hashing algorithms
// - sha3 keccak 256

/*
 How to implement?
 Problem space of computation, solution space of objects(types) or functions
 Ultimately, an algorithm will map to a procedure.
 Object (type) holds some data and has algorithms attached to itself.

 a) mapping to objects:
    EcdsaSecp256k1
        sign(message, key) -> signature
        verify(message, signature, public key) -> valid or invalid
            recover(message, signature) -> public key

    EthLegacy
        sign(message, key) -> signature
            hash: sha3 keccak 256 (message) -> EcdsaSecp256k1. sign -> signature
            signature.v + 27
        verify(message, signature, address) -> valid or invalid
            hash: sha3-keccak-256(message)
            signature.v - 27 (convert to underlying crypto)
            EcdsaSecp256k1.recover()

    EthProtected
        sign()
            hash: hasher of a message. But also, hasher of a transaction! Well, message is binary.
                so, the transaction to raw data happens outside of signing, but is coupled with the way
                how transaction is represented. I.e. legacy is hashing 6 values
                eip-155 is hashing 9 values. Eip-155 is the default now.
            signature with chain id!

    EthSign
        sign(message, key) -> signature
            transform message to modified message to hash
            sign with EthLegacy? or with protected? both could be requested. Protected is the default.

        verify(message, signature, address)
            transform message to hash
            verify using eth legacy or with protected?

    In all those ^^^, the signing and verification is a computation, a function, that doesn't require
    state and mutability. Can be expressed as a function.

    However, accessing a key is something that will require user interaction in the application.
    This can be moved outside of the scope of these functions, which will receive the private key.

    But the access to private key will require asynchronous operation.
    So, the functional call-return design breaks here, too.

    But this breaks with contract signatures, because they are state-based and require
    user and backend interaction.


    What about eip-1271 signing?
        let's hold off this for a moment

    What about pre-validated (on-chain) signing?
    SafeOnChainSign
        sign(message, account address) -> SafePre-ValidatedSignature
            here, call & return breaks.

            need to make an approveHash() etherum transaction, sign it with account's private key
                which will require user interaction
                will require backend communication for gas estimation
                then, eventually, using the EthProtected to sign() the transaction.

            Then only the pre-validated signature is created as a record in the contract
            and can be returned or saved, so that this signature can be put into
            execTransaction(... signatures), so that multisig threshold passes.

            Ok, so functional solution-space breaks: otherwise we have to introduce call-backs.

            Ok, so then those have to be objects that pass & receive messages.

 b) mapping to functions

    ecdsa_secp256k1_sign(key, message256) -> signature
    ecdsa_secp256k1_recover(signature, message256) -> public key

    sha3_keccak256(message) -> hash256

    ethereum_hash_tx_legacy(tx) -> hash256
        rlp_encode(tx{6}) -> binary
        sha3_keccak256(binary) -> hash256

    ethereum_sign_legacy(key, message256) -> signature
        ecdsa_secp256k1_sign(key, message256) -> signature
        signature.v += 27

    ethereum_hash_tx(tx) -> hash256
        rlp_encode(tx{9}) -> binary
        sha3_keccak256(binary) -> hash256

    ethereum_sign(key, message256, chain_id) -> signature
        ecdsa_secp256k1_sign(key, message256) -> signature
        signature.v = signature.v + 2 * chain_id + 35

    ethereum_verify(signature, message256, chain_id, address) -> valid/invalid
        signature.v = signature.v - 2 * chain_id - 35
        public_key = ecdsa_secp256k1_verify(signature, message256)
        recovered_address = ethereum_address(public_key)
        address == recovered_address

    ethereum_hash_eth_sign_message(message) -> hash256
        binary = ... + message
        sha3_keccak256(binary) -> hash256

    safe_sign_approval(key, hash256, chain_id(?)) -> safe_prevalidated_signature
        eth_tx.data = safe.approveHash(hash256)
        async: estimate transaction fees
        tx_hash = ethereum_hash_tx(eth_tx)
        async? (user interaction) tx_signature = ethereum_sign(key, tx_hash, chain_id(?))
        raw_tx = rlp_encode(tx+signature)
        async: eth_sendRawTransaction -> eth_tx_hash
        successfully executed
        prevalidated_signature = {ethereum_address(public_key(key)), 0, 1}

        ^^^ all is not needed if the key will be sending executeTransaction, then it's validated by the blockchain
        via the signature of the transaction

        also, we need to share the prevalidated signature for the message with an owner that
        will be executing the transaction.
            that owner will collect all signatures for executing a transaction.

    safe_execute_transaction -> wallet_execute_transaction OR can be relay_execute_transaction


    In the pseudo-code, mapping to functions seems more compact and
    straightforward than mapping to objects.

    However, we have to deal with asynchronicity. If we break the function flow of signing
    and approval, then we split that algorithm and have to come back to it when
    the state changed, i.e. when response message arrives.
    Until that point we can't proceed with the process.

    async-await supposed to make it better, but then we complicate stuff with
    network error handling, etc. Message-passing seems to me a better mechanism.

 */

// ETHEREUM - SAFE BOUNDARY

// how to handle different contract versions? They define potentially different signature schemes.
// previous versions might still be out there. Supported or not supported - question.

struct SafeRawSignature {
    var head: Data // 64 bytes
    var type: UInt8 // 1 byte
    var tail: Data // >= 0 bytes
}

struct SafeECDSASignature {
    // recovers to address, who must be owner of the multisig
    var r: UInt256
    var s: UInt256
    // v == type
    var v: UInt8
    // type: (27...30)
    var type: UInt8
}

struct SafeEthSignSignature {
    // recovers to address, who must be owner of the multisig
    var r: UInt256
    var s: UInt256
    // v = type - 4
    var v: UInt256
    // type: (31..); type = v + 4
    var type: UInt256
}

struct SafeEIP1271ContractSignature {
    // contract signature verifier, must be owner of the multisig
    var verifier: Address
    // offset from beginning of safe signature data to contract signature
    var offset: UInt256
    // type = 0
    let type: UInt8 = 0
    var length: UInt256
    var signature: Data
}

struct SafePreValidatedSignature {
    // account that pre-validated a hash using approveHash() or a message sender, must be owner of the multisig
    var validator: Address
    // not used
    var reserved: Data
    // type = 1
    let type: UInt8 = 1
}

// when execTransaction(...) called, it needs signatures data - seralized signatures of owners.
// raw[] -> bytes (concat)

class ECSecp256k1Signer {
    func sign(message: Data, key: PrivateKey) throws -> ECSecp256k1ExtendedSignature {
        let sig = try key._store.sign(hash: Array<UInt8>(message))
        let result = ECSecp256k1ExtendedSignature(r: UInt256(sig.r), s: UInt256(sig.s), v: UInt8(sig.v))
        return result
    }
}

