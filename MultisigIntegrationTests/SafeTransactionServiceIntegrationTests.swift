//
//  SafeTransactionServiceIntegrationTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 17.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class SafeTransactionServiceIntegrationTests: XCTestCase {
    var service = SafeTransactionService(url: App.configuration.services.transactionServiceURL, logger: MockLogger())

    func testSafeInfo() {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            let result = try? self.service.safeInfo(at: "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
            XCTAssertEqual(result?.implementation, "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F")
            semaphore.signal()
        }
        semaphore.wait()
    }

    func test_safeInfo_whenSendingNotASafe_returns404Error() {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                _ = try self.service.safeInfo(at: "0xc778417E063141139Fce010982780140Aa0cD5Ab")
            } catch {
                guard error is HTTPClientError.EntityNotFound else {
                    XCTFail("Wrong error type \(error)")
                    semaphore.signal()
                    return
                }
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    func test_safeInfo_whenSendingNotNormalizedAddress_returns422Error() {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                _ = try self.service.safeInfo(at: "0x728cafe9fb8cc2218fb12a9a2d9335193caa07e0")
            } catch {
                guard error is HTTPClientError.EntityNotFound else {
                    XCTFail("Wrong error type \(error)")
                    semaphore.signal()
                    return
                }
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    func testBalances() {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            let result = try? self.service.safeBalances(at: "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
            XCTAssertTrue(result?.count ?? 0 > 0)
            semaphore.signal()
        }
        semaphore.wait()
    }

    func testTransactionsPageLoad() {
        let safes: [Address] = [
            "0x8E77c8D47372Be160b3DC613436927FCc34E1ec0",
            "0x3E742f4CcD32b3CD396218C25A321F38BD51597c",
            "0xba552E35816337Ffb52d8CEC20a151AaFD1e9a24",
            "0x6c45e1E08d14fFE6919c1275006F0eCB0F3e5e39",
            "0x7AA1B0B213493B7a3505f9AfF1BA615Dc576A63D",
            "0x840018fFfbdC9f2Ee8DA5D647f66afDAAebde080",
            "0x360C8AbfdBC4a43568E9a1F39179d86d15aC4FCA",
            "0x5c86B4841caAd0e8e8Ed9F9A837670f7676e7ec7",
            "0xD273610823dFf00Aebbefd1102F3C452d16Ee419",
            "0x3b1c2b0940C85458197E0D18690805d6F89547eE",
            "0x976DC99c50B916Ea9b5275979059BCe9f1A0B1D1",
            "0xD5D4763AE65aFfFD82e3aEe3ec9f21171A1d6e0e",
            "0x360C8AbfdBC4a43568E9a1F39179d86d15aC4FCA",
            "0x2F4A6d752c8F433c5BbCde73FAc97Aa4bdE787AB",
            "0xCF5486D8C09D49A7396311950D1761c5fEF22551",
            "0x5d2F66B7b591198cA36450EFB56823EE26967144",
            "0xb19BDaFf408bB502Ae348aF731C3812670667224",
        ]
        continueAfterFailure = false
        for safe in safes {
            goThroughAllTransactions(safe: safe)
        }
    }

    func goThroughAllTransactions(safe: Address, line: UInt = #line) {
        var receivedError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                var offset = 0
                let limit = 100
                var remoteCount = 0
                var localCount = 0
                var pages: [TransactionsRequest.Response] = []
                repeat {
                    let page = try self.service.transactions(address: safe, offset: offset, limit: limit)
                    pages.append(page)
                    remoteCount = page.results.count
                    localCount = pages.map { $0.results.count }.reduce(0, +)
                    offset += page.results.count
                } while localCount < remoteCount

            } catch {
                receivedError = error
            }
            semaphore.signal()
        }
        semaphore.wait()

        XCTAssertNil(receivedError, "Safe \(safe.checksummed): \(String(describing: receivedError))", line: line)
    }

    func testTransactionByHash() {
        let safeTxHash = "0xa2a1079e3856e0ef817a8a5279fc967b9a7a4ddecd8e6bb654c0551a0b0b56f4"
        let safeTx = fetchTransaction(hash: safeTxHash)
        switch safeTx {
        case .success(let tx):
            XCTAssertEqual(tx.safe?.address, "0x1230B3d59858296A31053C1b8562Ecf89A2f888b")
        case .failure(let error):
            XCTFail("Unexpected error: \(error)")
        }

        // currently unsupported by the server
        let ethTxHash = "0x48e31efdd79cd6689f0e42c3aa02993a2f6906662671a72e646dc28c8935422a"
        let ethTx = fetchTransaction(hash: ethTxHash)
        switch ethTx {
        case .success(let tx):
            XCTAssertEqual(tx.safe?.address, "0x1230B3d59858296A31053C1b8562Ecf89A2f888b")
            XCTAssertEqual(tx.safeTxHash?.data, Data(hex: safeTxHash))
        case .failure(let error):
            XCTFail("Existing transaction not found: \(error)")
        }

        let invalidHash = "0x0000000000000000000042c3aa02993a2f6906662671a72e646dc28c8935422a"
        let invalidTx = fetchTransaction(hash: invalidHash)
        switch invalidTx {
        case .success(let tx):
            XCTFail("Unexpected transaction: \(tx)")
        case .failure(let error):
            guard error is HTTPClientError.EntityNotFound else {
                XCTFail("Expected 'not found' error, got this: \(error)")
                return
            }
        }
    }

    func fetchTransaction(hash: String) -> Result<CGSTransaction, Error> {
        var result: Result<CGSTransaction, Error>?
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            do {
                let tx = try self.service.transaction(hash: Data(hex: hash))
                result = .success(tx)
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }
        semaphore.wait()

        return result!
    }
}
