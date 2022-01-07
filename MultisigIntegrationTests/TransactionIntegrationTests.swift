//
//  TransactionIntegrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 20.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
import Ethereum
import JsonRpc2
import CryptoSwift
import Solidity
import Web3
@testable import Multisig

class TransactionIntegrationTests: XCTestCase {
    // execute tx
        // with a private key
        // with a ledger key
        // with a WC key

        // using eth_sign
        // using eth_personalSign
        // using eth_signTypedData (v1, v2, v3, v4)?

        // with enough confirmations
        // with not enough confirmations

        // gas estimation from chain
        // gas estimation from gas station

        // from CGW transaction details
        // from WC transaction details

        // safe implementation version
            // 0.0.1
            // 0.0.2
            // 1.0.0
            // 1.1.1
            // 1.3.0

        // with operation
            // call
            // delegate call

        // types:
            // send native coin
            // send erc20
            // send erc721
            // change safe settings
                // add owner with changing threshold
                // remove owner with changing threshold
                // swap owner
                // change threshold
                // change implementation
                // set fallback handler
                // enable module
                // disable module
            // module transaction
            // custom contract call
            // rejection transaction
            // approve hash
            // multi-send
            // contract deployment transaction
                // safe deployment transaction
                // nft deployment transaction
                // erc20 deployment transaction

        // chains:
            // Ethereum
            // xDai
            // Polygon
            // Binance Smart Chain
            // Energy Web Chain
            // Volta
            // Arbitrum
            // Avalanche
            // Goerli
            // Rinkeby

    // make an eth transaction on a test network.
    func testEoaSendTestEth() throws {
        continueAfterFailure = false

        let client = JsonRpc2.Client(
            transport: JsonRpc2.ClientHTTPTransport(url: "https://rinkeby.infura.io/v3/fda31d5c85564ae09c97b1b970e7eb33"),
            serializer: JsonRpc2.DefaultSerializer())


        // need a private key for an account
        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))

        // sender address


        // create a transaction

        // sign the transaction
            // The signature_y_parity, signature_r, signature_s elements of this transaction represent a
            // secp256k1 signature over
            // keccak256(0x02 || rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, amount, data, access_list]))
                    // For the transaction to be valid, accessList must be of type [[{20 bytes}, [{32 bytes}...]]...], where ... means “zero or more of the thing to the left

        // transaction data:

        var tx = Eth.TransactionEip1559(
            chainId: 4,
            from: "728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            to: "Ad302A4b09402b41EC3Fb4981B63E4Dd141fed6d",
            value: Eth.Amount(value: 1, unit: Eth.Unit.wei).value,
            fee: Eth.Fee(
                // miner tip
                maxPriorityFee: Eth.Amount(value: 2, unit: Eth.Unit.gigawei).converted(to: Eth.Unit.wei).value
            )
        )

        let getEstimate = EthRpc1.eth_estimateGas(tx)
        let getTransactionCount = EthRpc1.eth_getTransactionCount(address: EthRpc1.Data(tx.from!), block: .tag(.pending))
        let getPrice = EthRpc1.eth_gasPrice()

        let batch = try JsonRpc2.BatchRequest(requests: [
            getEstimate.request(id: .int(1)),
            getTransactionCount.request(id: .int(2)),
            getPrice.request(id: .int(3))
        ])

        let estExp = expectation(description: "Estimate")
        client.send(request: batch) { batchResponse in
            defer { estExp.fulfill() }

            guard let batchResponse = batchResponse else {
                XCTFail("Failed to estimate")
                return
            }

            switch batchResponse {
            case .response:
                XCTFail("Failed batch request: \(batchResponse)")
                return

            case .array(let responses):

                guard let gasEstimateResponse = responses.first(where: { $0.id == .int(1) }),
                      let gasEstimateResult = gasEstimateResponse.result else {
                    XCTFail("Failed batch request: \(batchResponse)")
                    return
                }

                guard let transactionCountResponse = responses.first(where: { $0.id == .int(2) }),
                      let transactionCountResult = transactionCountResponse.result else {
                    XCTFail("Failed batch request: \(batchResponse)")
                    return
                }

                guard let priceResponse = responses.first(where: { $0.id == .int(3) }),
                      let priceResult = priceResponse.result else {
                    XCTFail("Failed batch request: \(batchResponse)")
                    return
                }

                do {
                    let gasEstimate: EthRpc1.Quantity<Sol.UInt64> = try getEstimate.result(from: gasEstimateResult)
                    let transactionCount: EthRpc1.Quantity<Sol.UInt64> = try getTransactionCount.result(from: transactionCountResult)
                    let baseFee: EthRpc1.Quantity<Sol.UInt256> = try getPrice.result(from: priceResult)

                    // # of transactions is 1 more than latest nonce
                    tx.nonce = transactionCount.storage
                    tx.fee.gas = gasEstimate.storage
                    tx.fee.maxFeePerGas = tx.fee.maxPriorityFee + baseFee.storage

                } catch {
                    XCTFail("Failed to decode value: \(error)")
                    return
                }
            }
        }
        waitForExpectations(timeout: 60, handler: nil)


//        // rlp-encode transaction items
//        let rlpTransaction = RlpCoder().encode([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, amount, data, access_list as [RlpCodable]])
//                // create preimage
//        let preImage = Data([0x02]) + rlpTransaction
//                // hash preimage
//        let hash = Data(SHA3(variant: .keccak256).calculate(for: preImage.bytes))
//                // sign the hash
        let txHash = tx.hashForSigning()

        print("Hash for signing:",  EthRpc1.Data(txHash.storage))
        print("Balance Needed:", Sol.UInt256(tx.fee.gas) * tx.fee.maxFeePerGas + tx.value)

        let signature = try privateKey._store.sign(hash: Array(txHash.storage.storage))

        tx.signature = try Eth.Signature(
            yParity: Sol.UInt256(signature.v), // ethereum signature reqs
            r: Sol.UInt256(Data(signature.r)),
            s: Sol.UInt256(Data(signature.s))
        )


        let publicKey = try EthereumPublicKey(
            message: tx.preImageForSigning().bytes,
            v: EthereumQuantity(quantity: BigUInt(signature.v)),
            r: EthereumQuantity(signature.r),
            s: EthereumQuantity(signature.s))

        XCTAssertEqual(publicKey.address.hex(eip55: false), tx.from!.description)


        // serialize the encoded data to String according to requirements of Etheruem JSON RPC API

        let rawTransaction = tx.rawTransaction()

        print("Raw Tx Hash:", EthRpc1.Data(tx.txHash()))

        let sendRawTxMethod = EthRpc1.eth_sendRawTransaction(transaction: rawTransaction)
        let request = try sendRawTxMethod.request(id: .int(1))


        let testExpectation = expectation(description: "Request")

        client.send(request: request) { response in
            defer {
                testExpectation.fulfill()
            }
            guard let response = response else {
                XCTFail("expecting response")
                return
            }

            if let error = response.error {
                XCTFail("Request failed: \(error)")
                return
            }

            do {
                let transactionHashOrZeroHash = try sendRawTxMethod.result(from: response.result!)

                print("Result tx hash:", transactionHashOrZeroHash)

                tx.hash = Eth.Hash(transactionHashOrZeroHash.storage)
            } catch {
                XCTFail("Result decoding failed: \(error)")
            }
        }

        waitForExpectations(timeout: 60.0, handler: nil)
    }

    // make an erc20 transaction on a test network.

    // make a safe transaction sending eth on a test network.

    // make a safe transaction sending erc20 on a test network.
}
