//
//  Signer.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

class Signer {
    struct Signature: Equatable {
        var value: String
        var signer: String
    }

    /// Signs the hash of the provided string with a stored private key.
    /// Currently the app can store only one private key.
    /// - Parameters:
    ///   - string: string to hash and sign
    /// - Throws: errors during sisgning process
    /// - Returns: Signature object containing hex(r) hex(s) hex(v + 27) as one strig of secp256k1 signature
    static func sign(_ string: String) throws -> Signature {
        let hash = EthHasher.hash(string.data(using: .utf8)!)
        return try sign(hash: hash)
    }

    /// Signs the hash with a stored private key by provided address.
    /// Currently the app can store only one private key.
    /// - Parameters:
    ///   - hash: hash to sign
    /// - Throws: errors during sisgning process
    /// - Returns: Signature object containing hex(r) hex(s) hex(v + 27) as one strig of secp256k1 signature
    static func sign(hash: Data) throws -> Signature {
        guard let pkData = try App.shared.keychainService.data(forKey: KeychainKey.ownerPrivateKey.rawValue) else {
            throw "Private key not found"
        }
        let privateKey = try EthereumPrivateKey(pkData.bytes)
        let signer = privateKey.address.hex(eip55: true)
        let eoaSignature = try privateKey.sign(hash: hash.bytes)
        let v = String(eoaSignature.v + 27, radix: 16)
        let signature = "\(eoaSignature.r.toHexString())\(eoaSignature.s.toHexString())\(v)"
        return Signature(value: signature, signer: signer)
    }
}
