//
//  SignTransactionRequest.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 17.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

struct SignTransactionRequest: JSONRequest {
    let safe: String


    let to: String?
    let value: String
    let data: String?
    let operation: Int
    let safeTxGas: String
    let baseGas: String
    let gasPrice: String
    let gasToken: String?
    let refundReceiver: String
    let nonce: String
    let contractTransactionHash: String
    let sender: String
    let signature: String?

    enum CodingKeys: String, CodingKey {
        case sender, to, nonce, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver,
             contractTransactionHash, data, operation, value, signature
    }

    enum RequestError: String, Error {
        case couldNotVerifySafeTxHash
    }

    init(transaction: Transaction, safeAddress: Address) throws {
        safe = safeAddress.checksummed
        to = transaction.to?.description
        value = transaction.value.description
        data = transaction.data?.description
        operation = transaction.operation.rawValue
        safeTxGas = transaction.safeTxGas.description
        baseGas = transaction.baseGas.description
        gasPrice = transaction.gasPrice.description
        gasToken = transaction.gasToken?.description
        refundReceiver = transaction.refundReceiver.description
        nonce = transaction.nonce.description
        contractTransactionHash = transaction.safeTxHash.description

        // Calculating safeTxHash (we will need to refactor it properly)

//        let ERC191MagicByte = Data([0x19])
//        let ERC191Version1Byte = Data([0x01])
//
//        // this value is the same for all contract versions
//        let DefaultEIP712SafeAppDomainSeparatorTypeHash =
//            Data(hex: "0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749")
//
////         this value is for contract versions 1.0.0 and 1.1.1 (probably for later versions as well)
//        let DefaultEIP712SafeAppTxTypeHash =
//            Data(ethHex: "0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8")
//
//        let safeTxEncodedData = [
//            DefaultEIP712SafeAppTxTypeHash,
//            Data(ethHex: to).leftPadded(to: 32),
//            Self.encodeUInt(UInt256(value)!),
//            EthHasher.hash(Data(ethHex: data)),
//            Self.encodeUInt(UInt256(operation)!),
//            Self.encodeUInt(UInt256(safeTxGas)!),
//            Self.encodeUInt(UInt256(baseGas)!),
//            Self.encodeUInt(UInt256(gasPrice)!),
//            Data(ethHex: gasToken).leftPadded(to: 32),
//            Data(ethHex: refundReceiver).leftPadded(to: 32),
//            Self.encodeUInt(UInt256(nonce)!)
//        ]
//        .reduce(Data()) { $0 + $1 }
//
//        let domainData = [
//            DefaultEIP712SafeAppDomainSeparatorTypeHash,
//            Data(ethHex: safe)
//        ].reduce(Data()) { $0 + $1 }
//
//        let dataToHash = [
//            ERC191MagicByte,
//            ERC191Version1Byte,
//            EthHasher.hash(domainData),
//            EthHasher.hash(safeTxEncodedData)
//        ].reduce(Data()) { $0 + $1 }
//
//
//        guard EthHasher.hash(dataToHash) == Data(ethHex: contractTransactionHash) else {
//            throw RequestError.couldNotVerifySafeTxHash
//        }

        let hashToSign = Data(ethHex: contractTransactionHash)

        guard let pkData = try? App.shared.keychainService.data(forKey: KeychainKey.ownerPrivateKey.rawValue),
              let pk = try? EthereumPrivateKey(pkData.bytes),
              let sig = try? pk.sign(hash: hashToSign.bytes) else {
            sender = ""
            signature = ""
            return
        }
        sender = pk.address.hex(eip55: true)

        let v = String(format:"%02X", sig.v + 27)
        signature = "\(sig.r.toHexString())\(sig.s.toHexString())\(v)"
    }

    static private func encodeUInt(_ value: UInt256) -> Data {
        return Data(ethHex: String(value, radix: 16)).leftPadded(to: 32).suffix(32)
    }

    var httpMethod: String { return "POST" }
    var urlPath: String { return "/api/v1/safes/\(safe)/transactions/" }

    typealias ResponseType = Response

    struct Response: Decodable {}
}

extension SafeTransactionService {
    func sign(transaction: Transaction, safeAddress: Address) throws -> SignTransactionRequest.Response {
        let request = try SignTransactionRequest(transaction: transaction, safeAddress: safeAddress)
        return try execute(request: request)
    }
}
