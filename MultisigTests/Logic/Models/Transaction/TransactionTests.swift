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
        let data = jsonData("TransferTransaction")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let _ = try decoder.decode(SCGModels.TransactionDetails.self, from: data)
    }

    func testHistoryTransactions() {
        let txJson = jsonData("HistoryTransactions")

        let sema = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                let clientGateway = SafeClientGatewayService(url: App.configuration.services.clientGatewayURL,
                                                     logger: LogService.shared)
                let page = try clientGateway.jsonDecoder.decode(HistoryTransactionsSummaryListRequest.ResponseType.self, from: txJson)
                XCTAssertEqual(page.results.count, 20)
            } catch {
                XCTFail("Failure in transactions: \(error)")
            }
            sema.signal()
        }
        sema.wait()
    }

    func testQueuedTransactions() {
        let txJson = jsonData("QueuedTransactions")

        let sema = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                let clientGateway = SafeClientGatewayService(url: App.configuration.services.clientGatewayURL,
                                                     logger: LogService.shared)
                let page = try clientGateway.jsonDecoder.decode(QueuedTransactionsSummaryListRequest.ResponseType.self, from: txJson)
                XCTAssertEqual(page.results.count, 20)
            } catch {
                XCTFail("Failure in transactions: \(error)")
            }
            sema.signal()
        }
        sema.wait()
    }

    func testTransactionDetails() {
        let txJson = jsonData("TransferTransaction")

        let sema = DispatchSemaphore(value: 0)
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
                    sema.signal()
                break
                }
            } catch {
                XCTFail("Failure in transactions: \(error)")
            }
            sema.signal()
        }
        sema.wait()
    }

    func testTransactoinEncodedData() throws {
        let tx = Transaction(to: "0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66",
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
            Safe.domainData(for: "0x092CC1854399ADc38Dad4f846E369C40D0a40307").toHexString().lowercased(),
            domainHashInput.lowercased()
        )
        XCTAssertEqual(
            tx.encodeTransactionData(for: "0x092CC1854399ADc38Dad4f846E369C40D0a40307").toHexString().lowercased(),
            txHashInput.lowercased()
        )
    }

    private func oneline(_ str: String) -> String {
        return str.replacingOccurrences(of: "\n", with: "")
    }
}
