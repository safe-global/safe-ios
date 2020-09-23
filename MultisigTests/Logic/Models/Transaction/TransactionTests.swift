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

    func testTransactionSummary() {
        let txJson = jsonData("Transactions")

        let sema = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                let clientGateway = SafeClientGatewayService(url: App.configuration.services.clientGatewayURL,
                                                     logger: LogService.shared)
                let page = try clientGateway.jsonDecoder.decode(TransactionSummaryListRequest.ResponseType.self, from: txJson)
                let models = page.results.flatMap { tx in TransactionViewModel.create(from: tx) }
                XCTAssertEqual(page.results.count, models.count)
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
                let models = TransactionViewModel.create(from: transaction)
                XCTAssertEqual(models.count, 1)

                guard models.first! is TransferTransactionViewModel else {
                    XCTFail("Unexpected type: \(type(of: models.first))")
                    sema.signal()

                    return
                }
            } catch {
                XCTFail("Failure in transactions: \(error)")
            }
            sema.signal()
        }
        sema.wait()
    }
}
