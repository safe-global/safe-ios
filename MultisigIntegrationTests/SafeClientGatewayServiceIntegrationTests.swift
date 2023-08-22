//
//  SafeClientGatewayServiceIntegrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class SafeClientGatewayServiceIntegrationTests: CoreDataTestCase {
    var service = SafeClientGatewayService(url: App.configuration.services.clientGatewayURL, logger: MockLogger())
    let chainId = Chain.ChainID.ethereumRinkeby

    func testTransactionsPageLoad() throws {
        // configure dependency on nativeCoin to decode native token transactions
        let chain = try makeChain(id: chainId)
        let safe = createSafe(name: "safe", address: "0x1230B3d59858296A31053C1b8562Ecf89A2f888b", chain: chain)
        safe.select()
        XCTAssertNotNil(Chain.nativeCoin)

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
            "0x1230B3d59858296A31053C1b8562Ecf89A2f888b",
        ]
        continueAfterFailure = false
        for safe in safes {
            goThroughAllTransactions(safe: safe)
        }
    }

    private func goThroughAllTransactions(safe: Address, line: UInt = #line) {
        var page: Page<SCGModels.TransactionSummaryItem>?
        var pages = [Page<SCGModels.TransactionSummaryItem>]()

        let firstPageExp = expectation(description: "first page")

        _ = service.asyncHistoryTransactionsSummaryList(safeAddress: safe, chainId: chainId) { result in
            guard case .success(let response) = result else {
                XCTFail("Unexpected error: \(result); Safe \(safe.checksummed)", line: line)
                firstPageExp.fulfill()
                return
            }
            page = response
            pages.append(page!)

            firstPageExp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)


        while let nextPageUri = page?.next {

            do {
                let pageExp = expectation(description: "Page \(nextPageUri)")

                _ = try service.asyncHistoryTransactionsSummaryList(pageUri: nextPageUri) { result in
                    guard case .success(let response) = result else {
                        XCTFail("Unexpected error: \(result); Safe \(safe.checksummed)", line: line)
                        pageExp.fulfill()
                        return
                    }

                    page = response
                    pages.append(response)

                    pageExp.fulfill()
                }

                waitForExpectations(timeout: 3, handler: nil)
            } catch {
                XCTFail("Unexpected error :\(error.localizedDescription); Safe \(safe.checksummed)", line: line)
            }
        }
    }

    func testTransactionDetails() {
        let safeTxHash = "0xa2a1079e3856e0ef817a8a5279fc967b9a7a4ddecd8e6bb654c0551a0b0b56f4"
        let safeTx = fetchTransaction(safeTxHash: safeTxHash)
        switch safeTx {
        case .success(let tx):
            if case .multisig(let info) = tx.detailedExecutionInfo {
                XCTAssertEqual(info.safeTxHash.hash, Data(hex: safeTxHash))
            } else {
                XCTFail("Unexpected tx: \(tx)")
            }
            break
        case .failure(let error):
            XCTFail("Unexpected error: \(error)")
        }

        // currently unsupported by the server
//        let ethTxHash = "0x48e31efdd79cd6689f0e42c3aa02993a2f6906662671a72e646dc28c8935422a"
//        let ethTx = fetchTransaction(safeTxHash: ethTxHash)
//        switch ethTx {
//        case .success(let tx):
//            if case .multisig(let info) = tx.detailedExecutionInfo {
//                XCTAssertEqual(info.safeTxHash.hash, Data(hex: safeTxHash))
//            } else {
//                XCTFail("Unexpected tx: \(tx)")
//            }
//        case .failure(let error):
//            XCTFail("Existing transaction not found: \(error)")
//        }

        let invalidHash = "0x0000000000000000000042c3aa02993a2f6906662671a72e646dc28c8935422a"
        let invalidTx = fetchTransaction(safeTxHash: invalidHash)
        switch invalidTx {
        case .success(let tx):
            XCTFail("Unexpected transaction: \(tx)")
        case .failure(let error):
            guard error is GSError.EntityNotFound else {
                XCTFail("Expected 'not found' error, got this: \(error)")
                return
            }
        }

        let id = "multisig_0xEefFcdEAB4AC6005E90566B08EAda3994A573C1E_0xcef14524299252e348b299e23f6e36e66e2c6307993c0875d0640db482051c6b"
        let idTx = fetchTransaction(id: id)
        switch idTx {
        case .success(let tx):
            if case .custom(let info) = tx.txInfo {
                XCTAssertEqual(info.dataSize.value, 75)
            } else {
                XCTFail("Unexpected tx: \(tx)")
            }
            break
        case .failure(let error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func fetchTransaction(safeTxHash: String) -> Result<SCGModels.TransactionDetails, Error> {
        let hash: Data = Data(hex: safeTxHash)
        var result: Result<SCGModels.TransactionDetails, Error>?
        let semaphore = DispatchSemaphore(value: 0)

        _ = service.asyncTransactionDetails(safeTxHash: hash, chainId: chainId) { _result in
            result = _result
            semaphore.signal()
        }
        semaphore.wait()

        return result!
    }

    private func fetchTransaction(id: String) -> Result<SCGModels.TransactionDetails, Error> {
        var result: Result<SCGModels.TransactionDetails, Error>?
        let semaphore = DispatchSemaphore(value: 0)

        _ = service.asyncTransactionDetails(id: id, chainId: chainId) { _result in
            result = _result
            semaphore.signal()
        }
        semaphore.wait()

        return result!
    }

    func testSafeInfo() {
        let semaphore = DispatchSemaphore(value: 0)
        _ = service.asyncSafeInfo(safeAddress: Address("0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"),
                                  chainId: chainId) { result in
            guard case .success(let info) = result else {
                XCTFail("Failed to load Safe Account info.")
                semaphore.signal()
                return
            }
            XCTAssertEqual(info.implementation.addressInfo.address,
                           Address("0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F"))
            semaphore.signal()
        }
        semaphore.wait()
    }

    func test_safeInfo_whenSendingNotASafe_returns404Error() {
        let semaphore = DispatchSemaphore(value: 0)
        _ = service.asyncSafeInfo(safeAddress: Address("0xc778417E063141139Fce010982780140Aa0cD5Ab"),
                                  chainId: chainId) { result in
            guard case .failure(let error) = result else {
                XCTFail("Expected error.")
                semaphore.signal()
                return
            }
            guard error is GSError.EntityNotFound else {
                XCTFail("Wrong error type \(error)")
                semaphore.signal()
                return
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    func testBalances() {
        let semaphore = DispatchSemaphore(value: 0)
        _ = service.asyncBalances(safeAddress: Address("0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"),
                                  chainId: chainId) { result in
            guard case .success(let response) = result else {
                XCTFail("Failed to load balances.")
                semaphore.signal()
                return
            }
            XCTAssertTrue(response.items.count > 0)
            semaphore.signal()
        }
        semaphore.wait()
    }
}
