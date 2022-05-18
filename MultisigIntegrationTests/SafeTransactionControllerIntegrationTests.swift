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
    let chainId = Chain.ChainID.ethereumRinkeby


    func testAddOwnerWithThreshold() throws {
        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))

        // safe with the key as owner

        // new owner address
        // new threshold

        // 0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0

        let proposingOwner: Address = "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0"

        let safeAddress: Address = "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F"


        // new owner
        // 0xf7798db5675c310ed890d3748a7dda74288b435b7b7570591f1c5ae587e31dea
        // 0xecd31A385a2f2288F979A467293e8cd52ef6aBD8

        let newOwner = try Sol.Address(Address("0xecd31A385a2f2288F979A467293e8cd52ef6aBD8").data32)
        let threshold = try Sol.UInt256(UInt256(1).data32)

        let addOwnerABI = GnosisSafe_v1_3_0.addOwnerWithThreshold(
                owner: newOwner,
                _threshold: threshold
        ).encode()

        let tx = Transaction(safeAddress: safeAddress,
                chainId: chainId,
                toAddress: safeAddress,
                contractVersion: "1.3.0",
                amount: "0",
                data: addOwnerABI,
                safeTxGas: "0",
                nonce: "0")

        guard let tx = tx else {
            XCTFail("TX not created")
            return
        }

        let signature = try SafeTransactionSigner().sign(tx, key: privateKey)
        let transactionSignature = signature.hexadecimal

        let exp = expectation(description: "proposing")

        SafeTransactionController.shared.proposeTransaction(
                transaction: tx,
                sender: proposingOwner,
                chainId: chainId,
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
        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))
        let proposingOwner: Address = "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0"
        let safeAddress: Address = "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F"
        //let threshold = try Sol.UInt256(UInt256(1).data32) // 1 should not fail
        let threshold = try Sol.UInt256(UInt256(0).data32) // 0 should fail when executed
        //let threshold = try Sol.UInt256(UInt256(20).data32) // 20 should fail when executed

        let changeThresholdABI = GnosisSafe_v1_3_0.changeThreshold(
                _threshold: threshold
        ).encode()

        let tx = Transaction(safeAddress: safeAddress,
                chainId: chainId,
                toAddress: safeAddress,
                contractVersion: "1.3.0",
                amount: "0",
                data: changeThresholdABI,
                safeTxGas: "0",
                nonce: "0")

        guard let tx = tx else {
            XCTFail("TX not created")
            return
        }

        let signature = try SafeTransactionSigner().sign(tx, key: privateKey)
        let transactionSignature = signature.hexadecimal

        let exp = expectation(description: "proposing")

        SafeTransactionController.shared.proposeTransaction(
                transaction: tx,
                sender: proposingOwner,
                chainId: chainId,
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


    func testChangeThreshold2() throws {
        let privateKey = try PrivateKey(data: Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))
        let proposingOwner: Address = "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0"
        let safeAddress: Address = "0x193BF1F9655eAA511d2255c0efF1D7693c59d77F"
        //let threshold = try Sol.UInt256(UInt256(1).data32) // 1 should not fail
        let threshold = try Sol.UInt256(UInt256(0).data32) // 0 should fail when executed
        //let threshold = try Sol.UInt256(UInt256(20).data32) // 20 should fail when executed

//        let changeThresholdABI = GnosisSafe_v1_3_0.changeThreshold(
//                _threshold: threshold
//        ).encode()
//
//        let tx = Transaction(safeAddress: safeAddress,
//                chainId: chainId,
//                toAddress: safeAddress,
//                contractVersion: "1.3.0",
//                amount: "0",
//                data: changeThresholdABI,
//                safeTxGas: "0",
//                nonce: "0")

//        guard let tx = tx else {
//            XCTFail("TX not created")
//            return
//        }

//        let signature = try SafeTransactionSigner().sign(tx, key: privateKey)
//        let transactionSignature = signature.hexadecimal

        let exp = expectation(description: "proposing") //?
        let safe = Safe.by(address: safeAddress.checksummed, chainId: "4")
        let tx = SafeTransactionController.shared.changeThreshold(safe: safe, safeTxGas: "0", nonce: "0", threshold: threshold)
        let signature = try SafeTransactionSigner().sign(tx, key: privateKey)
        let transactionSignature = signature.hexadecimal

        SafeTransactionController.shared.proposeTransaction(
                transaction: tx,
                sender: proposingOwner,
                chainId: chainId,
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
        let safe: Address = "0x1230B3d59858296A31053C1b8562Ecf89A2f888b"

        let exp = expectation(description: "get owners")

        SafeTransactionController.shared.getOwners(safe: safe, chain: Chain.mainnetChain()) { result in
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

}
