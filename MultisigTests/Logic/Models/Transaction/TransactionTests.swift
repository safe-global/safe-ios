//
//  TransactionTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 16.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class TransactionTests: XCTestCase {
    func jsonData(_ name: String) -> Data {
        try! Data(contentsOf: Bundle(for: Self.self).url(forResource: name, withExtension: "json")!)
    }

    func testDecodeDetails() throws {
        // https://safe-client.staging.gnosisdev.com/v1/chains/4/transactions/multisig_0x1230B3d59858296A31053C1b8562Ecf89A2f888b_0xcb1c34c70414323afccd4e0645b081518a05f69f09d6d9a6b6e2d7c38e851ad4
        
        let data = jsonData("TransferTransaction")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let _ = try decoder.decode(SCGModels.TransactionDetails.self, from: data)
    }

    func testHistoryTransactions() {
        // https://safe-client.staging.gnosisdev.com/v1/chains/4/safes/0x1230B3d59858296A31053C1b8562Ecf89A2f888b/transactions/history?cursor=limit%3D20%26offset%3D20&timezone_offset=0
        let txJson = jsonData("HistoryTransactions")

        let exp = expectation(description: "async decode")
        DispatchQueue.global().async {
            do {
                let clientGateway = SafeClientGatewayService(url: App.configuration.services.clientGatewayURL,
                                                     logger: LogService.shared)
                let page = try clientGateway.jsonDecoder.decode(HistoryTransactionsSummaryListRequest.ResponseType.self, from: txJson)
                XCTAssertEqual(page.results.count, 25)
            } catch {
                XCTFail("Failure in transactions: \(error)")
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testQueuedTransactions() {
        // https://safe-client.staging.gnosisdev.com/v1/chains/4/safes/0x1230B3d59858296A31053C1b8562Ecf89A2f888b/transactions/queued
        let txJson = jsonData("QueuedTransactions")

        let exp = expectation(description: "async decode")
        DispatchQueue.global().async {
            do {
                let clientGateway = SafeClientGatewayService(url: App.configuration.services.clientGatewayURL,
                                                     logger: LogService.shared)
                let page = try clientGateway.jsonDecoder.decode(QueuedTransactionsSummaryListRequest.ResponseType.self, from: txJson)
                XCTAssertEqual(page.results.count, 4)

                guard case let SCGModels.TransactionSummaryItem.transaction(transaction) = page.results[1],
                      case let SCGModels.TxInfo.settingsChange(txInfo) = transaction.transaction.txInfo,
                      case let SCGModels.TxInfo.SettingsChange.SettingsInfo.changeThreshold(changeThreshold) = txInfo.settingsInfo,
                      let executionInfo = transaction.transaction.executionInfo,
                      case let SCGModels.ExecutionInfo.multisig(multisigExecutionInfo) = executionInfo else {
                    XCTFail("Failed to decode transaction")
                    return
                }

                XCTAssertEqual(changeThreshold.threshold, 2)
                XCTAssertEqual(multisigExecutionInfo.nonce.value, 652)
                XCTAssertEqual(multisigExecutionInfo.confirmationsRequired, 1)
                XCTAssertEqual(multisigExecutionInfo.confirmationsSubmitted, 1)
            } catch {
                XCTFail("Failure in transactions: \(error)")
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testTransactionDetails() {
        // https://safe-client.staging.gnosisdev.com/v1/chains/4/transactions/multisig_0x1230B3d59858296A31053C1b8562Ecf89A2f888b_0xcb1c34c70414323afccd4e0645b081518a05f69f09d6d9a6b6e2d7c38e851ad4
        let txJson = jsonData("TransferTransaction")

        let exp = expectation(description: "async decode")
        DispatchQueue.global().async {
            do {
                let clientGateway = SafeClientGatewayService(url: App.configuration.services.clientGatewayURL,
                                                     logger: LogService.shared)

                let transaction = try clientGateway.jsonDecoder.decode(TransactionDetailsRequest.ResponseType.self, from: txJson)

                switch transaction.txInfo {
                case .transfer(_):
                    break
                default:
                    XCTFail("Unexpected type: \(type(of: transaction))")
                }
            } catch {
                XCTFail("Failure in transactions: \(error)")
            }

            exp.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testTransactoinEncodedData_v1_2_0() throws {
        var tx = Transaction(to: "0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66",
                             value: "1000123",
                             data: "0x561001057600080fd5b5060405161060a3803806106",
                             operation: .delegate,
                             safeTxGas: "21000",
                             baseGas: "29943",
                             gasPrice: "99123001",
                             gasToken: "0x1001230000000000000000000000000000000001",
                             refundReceiver: AddressString(.zero),
                             nonce: "12305734256",
                             safeTxHash: nil)

        tx.safe = "0x092CC1854399ADc38Dad4f846E369C40D0a40307"
        tx.safeVersion = "1.2.0"
        tx.chainId = "4"

        let domainHashInput = oneline("""
035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749
000000000000000000000000092CC1854399ADc38Dad4f846E369C40D0a40307
""")
        let domainHash = EthHasher.hash(Data(ethHex: domainHashInput))

        let valueHashInput = oneline("""
bb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8
0000000000000000000000008e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66
00000000000000000000000000000000000000000000000000000000000F42BB
ef8553f949acc5f0cb8002523b7a4f8e02664b6637eddc74ad72bb8e38588309
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000005208
00000000000000000000000000000000000000000000000000000000000074F7
0000000000000000000000000000000000000000000000000000000005E87F39
0000000000000000000000001001230000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000002DD7A9A70
""")
        let valueHash = EthHasher.hash(Data(ethHex: valueHashInput))
        let ERC191MagicNumber = "1901"
        let txHashInput = ERC191MagicNumber + domainHash.toHexString() + valueHash.toHexString()

        XCTAssertEqual(tx.safeEncodedTxData.toHexString().lowercased(), valueHashInput.lowercased())
        XCTAssertEqual(
            Safe.domainData(for: "0x092CC1854399ADc38Dad4f846E369C40D0a40307", version: "1.2.0", chainId: "4")
                .toHexString().lowercased(),
            domainHashInput.lowercased()
        )
        XCTAssertEqual(            
            tx.encodeTransactionData().toHexString().lowercased(),
            txHashInput.lowercased()
        )
    }

    func testTransactoinEncodedData_v1_3_0() throws {
        var tx = Transaction(to: "0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66",
                             value: "1000123",
                             data: "0x561001057600080fd5b5060405161060a3803806106",
                             operation: .delegate,
                             safeTxGas: "21000",
                             baseGas: "29943",
                             gasPrice: "99123001",
                             gasToken: "0x1001230000000000000000000000000000000001",
                             refundReceiver: AddressString(.zero),
                             nonce: "12305734256",
                             safeTxHash: nil)

        tx.safe = "0x092CC1854399ADc38Dad4f846E369C40D0a40307"
        tx.safeVersion = "1.3.0"
        tx.chainId = "137"

        let domainHashInput = oneline("""
47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218
0000000000000000000000000000000000000000000000000000000000000089
000000000000000000000000092CC1854399ADc38Dad4f846E369C40D0a40307
""")
        let domainHash = EthHasher.hash(Data(ethHex: domainHashInput))

        let valueHashInput = oneline("""
bb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8
0000000000000000000000008e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66
00000000000000000000000000000000000000000000000000000000000F42BB
ef8553f949acc5f0cb8002523b7a4f8e02664b6637eddc74ad72bb8e38588309
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000005208
00000000000000000000000000000000000000000000000000000000000074F7
0000000000000000000000000000000000000000000000000000000005E87F39
0000000000000000000000001001230000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000002DD7A9A70
""")
        let valueHash = EthHasher.hash(Data(ethHex: valueHashInput))
        let ERC191MagicNumber = "1901"
        let txHashInput = ERC191MagicNumber + domainHash.toHexString() + valueHash.toHexString()

        XCTAssertEqual(tx.safeEncodedTxData.toHexString().lowercased(), valueHashInput.lowercased())
        XCTAssertEqual(
            Safe.domainData(for: "0x092CC1854399ADc38Dad4f846E369C40D0a40307", version: "1.3.0", chainId: "137")
                .toHexString().lowercased(),
            domainHashInput.lowercased()
        )
        XCTAssertEqual(
            tx.encodeTransactionData().toHexString().lowercased(),
            txHashInput.lowercased()
        )
    }

    private func oneline(_ str: String) -> String {
        return str.replacingOccurrences(of: "\n", with: "")
    }
}
