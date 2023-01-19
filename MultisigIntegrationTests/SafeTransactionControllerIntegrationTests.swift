//
//  SafeTransactionControllerIntegrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import JsonRpc2
import Solidity
import Ethereum
import SafeAbi

class SafeTransactionControllerIntegrationTests: CoreDataTestCase {
    var service = SafeClientGatewayService(url: App.configuration.services.clientGatewayURL, logger: MockLogger())
    let rinkebyChainId = Chain.ChainID.ethereumRinkeby
    let privateKey = try! PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))
    let proposingOwner: Address = "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0"

    func testAddOwnerWithThreshold() throws {
        let newOwner = Address("0xecd31A385a2f2288F979A467293e8cd52ef6aBD8")
        let defaultSafe = createSafe(name: "foo", address: "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F", chain: try! makeChain(id: "4"))
        let threshold = 1

        let exp = expectation(description: "proposing") //?
        let tx = SafeTransactionController.shared.addOwnerWithThresholdTransaction(safe: defaultSafe, safeTxGas: nil, nonce: "1", owner: newOwner, threshold: threshold)!
        let signature = try Wallet.shared.sign(tx, key: privateKey)
        let transactionSignature = signature.hexadecimal

        proposeTransaction(
                transaction: tx,
                sender: proposingOwner,
                chainId: rinkebyChainId,
                signature: transactionSignature
        ) { result in
            do {
                let txDetails = try result.get()
                print(txDetails)
            } catch {
                XCTFail("Failed: \(error)")
            }

            exp.fulfill()
        }

        waitForExpectations(timeout: 15)
    }

    func testChangeThreshold() throws {
        let safeAddress: Address = "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F"
        let defaultSafe = createSafe(name: "foo", address: "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F", chain: try! makeChain(id: "4"))
        let threshold = 1

        let exp = expectation(description: "proposing") //?
        let tx = SafeTransactionController.shared.changeThreshold(safe: defaultSafe, safeTxGas: nil, nonce: "1", threshold: threshold)!
        let signature = try Wallet.shared.sign(tx, key: privateKey)
        let transactionSignature = signature.hexadecimal

        proposeTransaction(
                transaction: tx,
                sender: proposingOwner,
                chainId: rinkebyChainId,
                signature: transactionSignature
        ) { result in
            do {
                let txDetails = try result.get()
                print(txDetails)
            } catch {
                XCTFail("Failed: \(error)")
            }

            exp.fulfill()
        }

        waitForExpectations(timeout: 15)
    }

    func testGetOwners() throws {
        let safeAddress: Address = "0x1230B3d59858296A31053C1b8562Ecf89A2f888b"

        let exp = expectation(description: "get owners")

        SafeTransactionController.shared.getOwners(safe: safeAddress, chain: Chain.mainnetChain()) { result in
            do {
                let addresses = try result.get()
                print(addresses)
            } catch {
                XCTFail("Failed: \(error)")
            }

            exp.fulfill()
        }

        waitForExpectations(timeout: 15)
    }

    func testReplaceOwner() throws {
        let oldOwner: Address = "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0"
        let newOwner = Address("0xecd31A385a2f2288F979A467293e8cd52ef6aBD8")
        let safeAddress: Address = "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F"
        let defaultSafe = createSafe(name: "foo", address: "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F", chain: try! makeChain(id: "4"))
        let threshold = 1

        let exp = expectation(description: "proposing")
        let tx = SafeTransactionController.shared.replaceOwner(safe: defaultSafe, prevOwner: nil, oldOwner: oldOwner, newOwner: newOwner, safeTxGas: nil, nonce: "1")!
        let signature = try Wallet.shared.sign(tx, key: privateKey)
        let transactionSignature = signature.hexadecimal

        proposeTransaction(
                transaction: tx,
                sender: proposingOwner,
                chainId: rinkebyChainId,
                signature: transactionSignature
        ) { result in
            do {
                let txDetails = try result.get()
                print(txDetails)
            } catch {
                XCTFail("Failed: \(error)")
            }

            exp.fulfill()
        }

        waitForExpectations(timeout: 15)
    }

    func testRemoveOwner() throws {
        let oldOwner: Address = "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0"
        let safeAddress: Address = "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F"
        let defaultSafe = createSafe(name: "foo", address: "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F", chain: try! makeChain(id: "4"))
        let threshold = 1

        let exp = expectation(description: "proposing")
        let tx = SafeTransactionController.shared.removeOwner(safe: defaultSafe, safeTxGas: nil, prevOwner: nil, oldOwner: oldOwner, nonce: "1", threshold: threshold)!
        let signature = try Wallet.shared.sign(tx, key: privateKey)
        let transactionSignature = signature.hexadecimal

        proposeTransaction(
                transaction: tx,
                sender: proposingOwner,
                chainId: rinkebyChainId,
                signature: transactionSignature
        ) { result in
            do {
                let txDetails = try result.get()
                print(txDetails)
            } catch {
                XCTFail("Failed: \(error)")
            }

            exp.fulfill()
        }

        waitForExpectations(timeout: 15)
    }

    // Helper methods
    func proposeTransaction(transaction: Transaction,
                            sender: Address,
                            chainId: String,
                            signature: String,
                            completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        let task = App.shared.clientGatewayService.asyncProposeTransaction(transaction: transaction,
                sender: AddressString(sender),
                signature: signature,
                chainId: chainId) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                switch result {
                case .failure(let error):
                    if (error as NSError).code == URLError.cancelled.rawValue &&
                               (error as NSError).domain == NSURLErrorDomain {
                        // Estimation was canceled, ignore.
                        return
                    }

                default: break
                }

                completion(result)
            }
        }
        return task
    }

}
