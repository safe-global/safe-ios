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

    func testAddOwner() {
        let txJson = jsonData("addOwnerWithThreshold_tx")
        let infoJson = jsonData("addOwnerWithThreshold_safe")

        let sema = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                let service = SafeTransactionService(url: App.configuration.services.transactionServiceURL, logger: LogService.shared)

                let page = try service.jsonDecoder.decode(TransactionsRequest.Response.self, from: txJson)
                let info = try service.jsonDecoder.decode(SafeStatusRequest.Response.self, from: infoJson)
                let models = page.results.flatMap { tx in TransactionViewModel.create(from: tx, info) }
                XCTAssertEqual(page.results.count, models.count)

                guard let tx = models.first as? SettingChangeTransactionViewModel else {
                    XCTFail("Unexpected type: \(type(of: models.first))")
                    sema.signal()

                    return
                }

                XCTAssertEqual(tx.title, MethodRegistry.GnosisSafeSettings.AddOwnerWithThreshold.signature.name)
            } catch {
                XCTFail("Failure in transactions: \(error)")
            }
            sema.signal()
        }
        sema.wait()
    }
}
