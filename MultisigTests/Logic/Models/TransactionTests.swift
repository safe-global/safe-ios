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

    func testAddOwner() {
        let txJson = """
{
"count": 59,
"next": "https://safe-transaction.staging.gnosisdev.com/api/v1/safes/0xaE3c91c89153DEaC332Ab7BBd167164978638c30/all-transactions/?limit=20&offset=20",
"previous": null,
"results": [
    {
      "safe": "0xaE3c91c89153DEaC332Ab7BBd167164978638c30",
      "to": "0xaE3c91c89153DEaC332Ab7BBd167164978638c30",
      "value": "0",
      "data": "0x0d582f13000000000000000000000000ae3c91c89153deac332ab7bbd167164978638c300000000000000000000000000000000000000000000000000000000000000001",
      "operation": 0,
      "gasToken": "0x0000000000000000000000000000000000000000",
      "safeTxGas": 0,
      "baseGas": 0,
      "gasPrice": "0",
      "refundReceiver": "0x0000000000000000000000000000000000000000",
      "nonce": 0,
      "executionDate": "2019-12-18T13:21:04Z",
      "submissionDate": "2019-12-18T13:21:04Z",
      "modified": "2019-12-18T13:21:04Z",
      "blockNumber": 5635732,
      "transactionHash": "0x059064a8cdb0f3a695e52e4dfdcd1816ef26cf0bda8d45e20d17ff15e7b7c9ef",
      "safeTxHash": "0xce278a29925e6cedaf1d7ba7095c6921adb3c1e88b2337210b5c99e68fe0f6d9",
      "executor": "0x0e329fa8d6Fcd1ba0Cda495431F1f7CA24F442C2",
      "isExecuted": true,
      "isSuccessful": true,
      "ethGasPrice": "1000000000",
      "gasUsed": 94973,
      "fee": "94973000000000",
      "origin": null,
      "dataDecoded": {
        "method": "addOwnerWithThreshold",
        "parameters": [
          {
            "name": "owner",
            "type": "address",
            "value": "0xaE3c91c89153DEaC332Ab7BBd167164978638c30"
          },
          {
            "name": "_threshold",
            "type": "uint256",
            "value": "1"
          }
        ]
      },
      "confirmationsRequired": 1,
      "confirmations": [
        {
          "owner": "0x0e329fa8d6Fcd1ba0Cda495431F1f7CA24F442C2",
          "submissionDate": "2020-03-13T18:40:34.514726Z",
          "transactionHash": null,
          "confirmationType": "CONFIRMATION",
          "signature": "0x0000000000000000000000000e329fa8d6fcd1ba0cda495431f1f7ca24f442c2000000000000000000000000000000000000000000000000000000000000000001",
          "signatureType": "APPROVED_HASH"
        }
      ],
      "signatures": "0x0000000000000000000000000e329fa8d6fcd1ba0cda495431f1f7ca24f442c2000000000000000000000000000000000000000000000000000000000000000001",
      "transfers": [],
      "txType": "MULTISIG_TRANSACTION"
    }
  ]
}
"""
        .data(using: .utf8)!
        let infoJson = """
{
  "address": "0xaE3c91c89153DEaC332Ab7BBd167164978638c30",
  "nonce": 49,
  "threshold": 2,
  "owners": [
    "0x39cBD3814757Be997040E51921e8D54618278A08",
    "0x37ec10a601dA5FF8bA6f87f40EA3e8F3E50c7f18",
    "0x0e329fa8d6Fcd1ba0Cda495431F1f7CA24F442C2"
  ],
  "masterCopy": "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F",
  "modules": [],
  "fallbackHandler": "0xd5D82B6aDDc9027B22dCA772Aa68D5d74cdBdF44",
  "version": "1.1.1"
}
"""
        .data(using: .utf8)!

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
