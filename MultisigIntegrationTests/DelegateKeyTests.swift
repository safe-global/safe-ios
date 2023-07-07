//
//  DelegateKeyTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 14.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import SafeWeb3

class DelegateKeyTests: XCTestCase {

    var delegatorKey: PrivateKey!
    var delegateKey: PrivateKey!
    var chainId: String = "4"

    var clientGateway = App.shared.clientGatewayService

    func loadKeys() throws {
        // delegator key

        //  generate new one

//        let delegatorSeed = Data.randomBytes(length: 16)!
//        let delegatorMnemonic = BIP39.generateMnemonicsFromEntropy(entropy: delegatorSeed)!
//        delegatorKey = try PrivateKey(mnemonic: delegatorMnemonic, pathIndex: 0)
//        print("Created DELEGATOR key: \(delegatorKey.address.checksummed)\nMnemonic: \(delegatorMnemonic)\nPrivate key: \(delegatorKey.keyData.toHexStringWithPrefix())")

        // or import from mnemonic:

        delegatorKey = try PrivateKey(mnemonic: "obvious cart elephant coach move gain alpha mask size seed few powder", pathIndex: 0)
        print("Loaded DELEGATOR key from mnemonic: \(delegatorKey.address.checksummed)")

        // or import from private key

//      delegatorKey = try PrivateKey(data: Data(hex: "0x642ee134fdd0566100f3adf50e9ee33510947728da93669f487930f1b116b13e"))
//        print("Loaded DELEGATOR key from private key: \(delegatorKey.address.checksummed)")

        // delegate key

        // generate new one

//        let delegateSeed = Data.randomBytes(length: 16)!
//        let delegateMnemonic = BIP39.generateMnemonicsFromEntropy(entropy: delegateSeed)!
//        delegateKey = try PrivateKey(mnemonic: delegateMnemonic, pathIndex: 0)
//        print("Created DELEGATE key: \(delegateKey.address.checksummed)\nMnemonic: \(delegateMnemonic)\nPrivate key: \(delegateKey.keyData.toHexStringWithPrefix())")

        // or load delegate key from mnemonic:

        delegateKey = try PrivateKey(mnemonic: "cricket tube parade unlock protect rib soccer reduce enemy educate special summer", pathIndex: 0)
        print("Loaded DELEGATE key from mnemonic: \(delegateKey.address.checksummed)")

        // or load delegate key from private key:

//        delegateKey = try PrivateKey(data: Data(hex: "0x22d50064b4ef2a5c9ad84c234403c000b2302367a649e77f223cc3815da2fb73"))
//        print("Loaded DELEGATE key from private key: \(delegateKey.address.checksummed)")
    }

    func testGenKeys() throws {
        try loadKeys()
    }

    func testGetDelegates() throws {
        try loadKeys()
        try getDelegates()
    }

    func testCreateDeleteByDelegator() throws {
        continueAfterFailure = false
        try loadKeys()
        try getDelegates()
        try createDelegate()
        try deleteDelegateByDelegator()
    }

    func testCreateDeleteByDelegate() throws {
        continueAfterFailure = false
        try loadKeys()
        try getDelegates()
        try createDelegate()
        try deleteDelegateByDelegate()
    }

    func delegateMessageSignature(by signer: PrivateKey) throws -> Data {
        // compose the 'delegating' message
        let timestamp = Int(Date().timeIntervalSince1970)
        print("Timestamp: \(timestamp)")

        let timestamp_div_3600 = timestamp / 3600
        print("Timestamp / 3600: \(timestamp_div_3600)")

        let message = delegateKey.address.checksummed + String(describing: timestamp_div_3600)
        print("Message: \(message)")

        let hash = EthHasher.hash(message)
        print("Hash: \(hash.toHexStringWithPrefix())")

        // sign it with DELEGATOR key:
        let signature = try signer.sign(hash: hash)
        print("Signature: \(signature.hexadecimal)")

        return Data(hex: signature.hexadecimal)
    }

    @discardableResult
    func getDelegates() throws -> Page<SCGModels.KeyDelegate>? {
        var delegates: Page<SCGModels.KeyDelegate>?

        let exp = expectation(description: "Async Get Delegate Request")
        clientGateway.asyncGetDelegate(
            chainId: chainId,
            delegator: delegatorKey.address
        ) { result in
            switch result {
            case .success(let resp):
                print("Delegates: \(resp.results)")
                delegates = resp
            case .failure(let error):
                print("Failed to get delegates: \(error)")
                XCTFail(error.localizedDescription)
            }

            exp.fulfill()
        }
        waitForExpectations(timeout: 300, handler: nil)
        return delegates
    }
    
    func createDelegate() throws {
        let signature = try delegateMessageSignature(by: delegatorKey)

        // create delegate
        let exp = expectation(description: "Async Create Delegate Request")

        let label = "iOS Test Delegate Key"

        clientGateway.asyncCreateDelegate(
            safe: nil,
            owner: delegatorKey.address,
            delegate: delegateKey.address,
            signature: signature,
            label: label,
            chainId: chainId
        ) { result in
            switch result {
            case .success:
                print("Created delegate")
            case .failure(let error):
                print("Failed to create delegate: \(error)")
                XCTFail(error.localizedDescription)
            }

            exp.fulfill()
        }
        waitForExpectations(timeout: 300, handler: nil)
    }

    func deleteDelegateByDelegate() throws {
        let signature = try delegateMessageSignature(by: delegateKey)

        let exp = expectation(description: "Async Delete Delegate Request")

        clientGateway.asyncDeleteDelegate(
            owner: delegatorKey.address,
            delegate: delegateKey.address,
            signature: signature.toHexStringWithPrefix(),
            chainId: chainId
        ) { result in
            switch result {
            case .success:
                print("Deleted delegate")
            case .failure(let error):
                print("Failed to delete delegate: \(error)")
                XCTFail(error.localizedDescription)
            }

            exp.fulfill()
        }
        waitForExpectations(timeout: 300, handler: nil)
    }

    func deleteDelegateByDelegator() throws {
        let signature = try delegateMessageSignature(by: delegatorKey)

        let exp = expectation(description: "Async Delete Delegate Request")

        clientGateway.asyncDeleteDelegate(
            owner: delegatorKey.address,
            delegate: delegateKey.address,
            signature: signature.toHexStringWithPrefix(),
            chainId: chainId
        ) { result in
            switch result {
            case .success:
                print("Deleted delegate")
            case .failure(let error):
                print("Failed to delete delegate: \(error)")
                XCTFail(error.localizedDescription)
            }

            exp.fulfill()
        }
        waitForExpectations(timeout: 300, handler: nil)
    }
}
