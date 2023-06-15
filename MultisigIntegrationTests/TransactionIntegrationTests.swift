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
import SafeWeb3
@testable import Multisig
import SafeAbi

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
    let client = JsonRpc2.Client(
        transport: JsonRpc2.ClientHTTPTransport(url: "https://rinkeby.infura.io/v3/fda31d5c85564ae09c97b1b970e7eb33"),
        serializer: JsonRpc2.DefaultSerializer())

    // make an eth transaction on a test network.
    func testEoaSendTestEthEip1559() throws {
        continueAfterFailure = false
        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))

        let minerTip = Eth.Amount(value: 2, unit: Eth.Unit.gigawei).converted(to: Eth.Unit.wei).value

        let tx = Eth.TransactionEip1559(
            chainId: 4,
            from: "728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            // eoa address
//            to: "Ad302A4b09402b41EC3Fb4981B63E4Dd141fed6d",
            // safe address
            to: "dd1D27C114aB45e8A650B251eDFA1b0795bbe020",
            value: Eth.Amount(value: 1, unit: Eth.Unit.kilowei).value,
            fee: Eth.Fee1559(
                maxFeePerGas: minerTip,
                maxPriorityFee: minerTip
            )
        )

        try send(tx: tx, using: privateKey)
    }

    func testEoaSendTestEthLegacyWithChainId() throws {
        continueAfterFailure = false
        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))

        let tx = Eth.TransactionLegacy(
            chainId: 4,
            from: "728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            // eoa address
//            to: "Ad302A4b09402b41EC3Fb4981B63E4Dd141fed6d",
            // safe address
            to: "dd1D27C114aB45e8A650B251eDFA1b0795bbe020",
            value: Eth.Amount(value: 1, unit: Eth.Unit.kilowei).value
        )

        try send(tx: tx, using: privateKey)
    }

    func testEoaSendTestEthLegacyWithoutChainId() throws {
        continueAfterFailure = false
        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))

        let tx = Eth.TransactionLegacy(
            from: "728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            // eoa address
//            to: "Ad302A4b09402b41EC3Fb4981B63E4Dd141fed6d",
            // safe address
            to: "dd1D27C114aB45e8A650B251eDFA1b0795bbe020",
            value: Eth.Amount(value: 1, unit: Eth.Unit.kilowei).value
        )

        try send(tx: tx, using: privateKey)
    }

    func testEoaSendTestEthEip2930() throws {
        continueAfterFailure = false
        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))

        let tx = Eth.TransactionEip2930(
            chainId: 4,
            from: "728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            // eoa address
//            to: "Ad302A4b09402b41EC3Fb4981B63E4Dd141fed6d",
            // safe address
            to: "dd1D27C114aB45e8A650B251eDFA1b0795bbe020",
            value: Eth.Amount(value: 1, unit: Eth.Unit.kilowei).value
        )

        try send(tx: tx, using: privateKey)
    }

    func testEoaSendTestErc20Eip1559() throws {
        continueAfterFailure = false
        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))

        let input = ERC20.transfer(
            // eoa address
//            to: "Ad302A4b09402b41EC3Fb4981B63E4Dd141fed6d",
            // safe address
            to: "dd1D27C114aB45e8A650B251eDFA1b0795bbe020",
            // (LOVE) has 6 decimals
            value: 1000
        ).encode()

        print("call data", input.toHexStringWithPrefix())

        let minerTip = Eth.Amount(value: 2, unit: Eth.Unit.gigawei).converted(to: Eth.Unit.wei).value

        let tx = Eth.TransactionEip1559(
            chainId: 4,
            from: "728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            // erc20 contract address (LOVE)
            to: "b3a4Bc89d8517E0e2C9B66703d09D3029ffa1e6d",
            // erc20 transfer call
            input: Sol.Bytes(storage: input),
            fee: Eth.Fee1559(
                maxFeePerGas: minerTip,
                maxPriorityFee: minerTip
            )
        )

        try send(tx: tx, using: privateKey)
    }

    func send(tx: EthTransaction, using privateKey: PrivateKey, line: UInt = #line) throws {
        var tx = tx

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
                XCTFail("Failed to estimate", line: line)
                return
            }

            switch batchResponse {
            case .response:
                XCTFail("Failed batch request: \(batchResponse)", line: line)
                return

            case .array(let responses):

                guard let gasEstimateResponse = responses.first(where: { $0.id == .int(1) }),
                      let gasEstimateResult = gasEstimateResponse.result else {
                    XCTFail("Failed batch request: \(batchResponse)", line: line)
                    return
                }

                guard let transactionCountResponse = responses.first(where: { $0.id == .int(2) }),
                      let transactionCountResult = transactionCountResponse.result else {
                    XCTFail("Failed batch request: \(batchResponse)", line: line)
                    return
                }

                guard let priceResponse = responses.first(where: { $0.id == .int(3) }),
                      let priceResult = priceResponse.result else {
                    XCTFail("Failed batch request: \(batchResponse)", line: line)
                    return
                }

                do {
                    let gasEstimate: EthRpc1.Quantity<Sol.UInt64> = try getEstimate.result(from: gasEstimateResult)
                    let transactionCount: EthRpc1.Quantity<Sol.UInt64> = try getTransactionCount.result(from: transactionCountResult)
                    let baseFee: EthRpc1.Quantity<Sol.UInt256> = try getPrice.result(from: priceResult)

                    tx.update(gas: gasEstimate.storage,
                              transactionCount: transactionCount.storage,
                              baseFee: baseFee.storage)

                } catch {
                    XCTFail("Failed to decode value: \(error)", line: line)
                    return
                }
            }
        }
        waitForExpectations(timeout: 60, handler: nil)

        let txHash = tx.hashForSigning()

        print("Hash for signing:",  EthRpc1.Data(txHash.storage))

        print("Balance Needed:", tx.requiredBalance)

        let signature = try privateKey._store.sign(hash: Array(txHash.storage.storage))

        try tx.updateSignature(
            v: Sol.UInt256(signature.v),
            r: Sol.UInt256(Data(signature.r)),
            s: Sol.UInt256(Data(signature.s))
        )

        let publicKey = try EthereumPublicKey(
            message: tx.preImageForSigning().bytes,
            v: EthereumQuantity(quantity: BigUInt(signature.v)),
            r: EthereumQuantity(signature.r),
            s: EthereumQuantity(signature.s))

        XCTAssertEqual(publicKey.address.hex(eip55: false), tx.from!.description, line: line)


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
                XCTFail("expecting response", line: line)
                return
            }

            if let error = response.error {
                XCTFail("Request failed: \(error)", line: line)
                return
            }

            do {
                let transactionHashOrZeroHash = try sendRawTxMethod.result(from: response.result!)

                print("Result tx hash:", transactionHashOrZeroHash)

                tx.hash = Eth.Hash(transactionHashOrZeroHash.storage)
            } catch {
                XCTFail("Result decoding failed: \(error)", line: line)
            }
        }

        waitForExpectations(timeout: 60.0, handler: nil)
    }

    // make a safe transaction sending eth on a test network.
    func testSafeSendEthTestEip1559() throws {
        continueAfterFailure = false

        // Get queue -> first transaction -> submit it

        // get tx queue
        let cgw = App.shared.clientGatewayService

        var queue: [SCGModels.TransactionSummaryItemTransaction] = []

        let queueExp = expectation(description: "Get Queue")
        _ = cgw.asyncQueuedTransactionsSummaryList(
            safeAddress: Address("0xdd1D27C114aB45e8A650B251eDFA1b0795bbe020"),
            chainId: "4"
        ) { result in
            defer {
                queueExp.fulfill()
            }
            switch result {
            case .failure(let error):
                XCTFail("Failed to get queue: \(error)")

            case .success(let page):
                let transactions = page.results.compactMap { item -> SCGModels.TransactionSummaryItemTransaction? in
                    switch item {
                    case .transaction(let txSummaryItem):
                        return txSummaryItem
                    default:
                        return nil
                    }
                }

                queue = transactions
            }
        }
        waitForExpectations(timeout: 60, handler: nil)

        guard let txSummary = queue.first else {
            XCTFail("Please create a transaction to execute")
            return
        }

        // get tx details

        var txDetails: SCGModels.TransactionDetails! = nil

        let detailsExp = expectation(description: "Get Tx Details")
        cgw.asyncTransactionDetails(
            id: txSummary.transaction.id,
            chainId: "4"
        ) { result in
            defer {
                detailsExp.fulfill()
            }
            switch result {
            case .failure(let error):
                XCTFail("Failed to get queue: \(error)")

            case .success(let details):

                txDetails = details
            }

        }
        waitForExpectations(timeout: 60, handler: nil)

        XCTAssertNotNil(txDetails)

        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))

        guard
            let execInfo = txDetails.detailedExecutionInfo,
            case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigDetails) = execInfo,
            let txData = txDetails.txData
        else {
            XCTFail("Tx Details missing execution info or txData!")
            return
        }

        // send transaction

        let signatures = multisigDetails.confirmations.sorted { lhs, rhs in
            lhs.signer.value.address.hexadecimal < rhs.signer.value.address.hexadecimal
        }.map { confirmation in
            confirmation.signature.data
        }.joined()

        let input = try GnosisSafe_v1_3_0.execTransaction(
            to:  Sol.Address(txData.to.value.data32),
            value: Sol.UInt256(txData.value.data32),
            data: Sol.Bytes(storage: txData.hexData?.data ?? Data()),
            operation: Sol.UInt8(txData.operation.rawValue),
            safeTxGas: Sol.UInt256(multisigDetails.safeTxGas.data32),
            baseGas: Sol.UInt256(multisigDetails.baseGas.data32),
            gasPrice: Sol.UInt256(multisigDetails.gasPrice.data32),
            gasToken: Sol.Address(multisigDetails.gasToken.data32),
            refundReceiver: Sol.Address(multisigDetails.refundReceiver.value.data32),
            // All the signatures are sorted by the signer address and concatenated
            signatures: Sol.Bytes(storage: Data(signatures))
        ).encode()

        print("call data", input.toHexStringWithPrefix())

        let minerTip = Eth.Amount(value: 2, unit: Eth.Unit.gigawei).converted(to: Eth.Unit.wei).value

        let tx = Eth.TransactionEip1559(
            chainId: 4,
            from: "728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            to: "dd1D27C114aB45e8A650B251eDFA1b0795bbe020",
            input: Sol.Bytes(storage: input),
            fee: Eth.Fee1559(
                maxFeePerGas: minerTip,
                maxPriorityFee: minerTip
            )
        )

        try send(tx: tx, using: privateKey)
    }
}
