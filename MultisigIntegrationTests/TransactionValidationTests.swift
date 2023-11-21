//
//  TransactionValidationTests.swift
//  MultisigTests
//
//  Created by Dmitrii Bespalov on 21.11.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import SafeWeb3
import Solidity

final class TransactionValidationTests: CoreDataTestCase {
    
    struct TestCase: Decodable {
        var chain: SCGModels.Chain
        var safe: SCGModels.SafeInfoExtended
        var tx: SCGModels.TransactionDetails
        
        init(chain: SCGModels.Chain, safe: SCGModels.SafeInfoExtended, tx: SCGModels.TransactionDetails) {
            self.chain = chain
            self.safe = safe
            self.tx = tx
        }
        
        init?(named name: String, extension ext: String = "json") {
            let bundle = Bundle(for: TransactionValidationTests.self)
            guard let url = bundle.url(forResource: name, withExtension: ext) else { return nil }
            let jsonDecoder = JSONDecoder()
            do {
                let data = try Data(contentsOf: url)
                self = try jsonDecoder.decode(TestCase.self, from: data)
            } catch {
                print("[TestCase] Failed to load: \(error)")
                return nil
            }
        }
    }
    
    func testTransactions() throws {
        // Happy Cases
        
        XCTAssertNoThrow(
            try validateTransactionCase("TransactionValidationTestCase1")
        )
        
        XCTAssertNoThrow(
            try validateTransactionCase("TransactionValidationTestCase_MultipleConfirmations")
        )
        
        
        XCTAssertNoThrow(
            try validateTransactionCase("TransactionValidationTestCase_AllSignatureTypes_v1_1_0")
        )
        
        XCTAssertNoThrow(
            try validateTransactionCase("TransactionValidationTestCase_AllSignatureTypes_v1_0_0")
        )
        
        // Invalid Cases
        
        XCTAssertThrowsError(
            try validateTransactionCase("TransactionValidationTestCase_InvalidSafeTxHash"),
            "expected 'Invalid safeTxHash' error",
            { e in
                XCTAssertEqual(e.localizedDescription, "Invalid safeTxHash. This may be a dangerous transaction.")
            }
        )
        
        XCTAssertThrowsError(
            try validateTransactionCase("TransactionValidationTestCase_NoConfirmations"),
            "expected 'No confirmations' error",
            { e in
                XCTAssertEqual(e.localizedDescription, "Transaction has no confirmations.")
            }
        )
        
        XCTAssertThrowsError(
            try validateTransactionCase("TransactionValidationTestCase_ConfirmationsNotFromOwners"),
            "expected 'Confirmations not from owners' error",
            { e in
                XCTAssertEqual(e.localizedDescription, "Not all confirmations are from safe owners.")
            }
        )

        XCTAssertThrowsError(
            try validateTransactionCase("TransactionValidationTestCase_SignerNotMatchingSignature"),
            "expected 'Signature' error",
            { e in
                XCTAssertEqual(e.localizedDescription, "Not all signatures are from safe's owners. This may be a dangerous transaction.")
            }
        )
    }
    
    func validateTransactionCase(_ testCaseName: String) throws {
        guard let testCase = TestCase(named: testCaseName) else {
            XCTFail("Failed to load test case")
            return
        }
        
        let chain = try Chain.create(testCase.chain)
        let safe = Safe.create(
            address: testCase.safe.address.value.description,
            version: testCase.safe.version,
            name: "Test",
            chain: chain
        )
        safe.update(from: testCase.safe)
        
        let vc = UIViewController()
        let tableView = UITableView()
        vc.view.addSubview(tableView)
        
        let builder = TransactionDetailCellBuilder(vc: vc, tableView: tableView, chain: chain)
        
        try builder.validate(tx: testCase.tx, safe: safe)
    }
    
    func testGenerateEthSignSignature() throws {
        let key = try PrivateKey(data:  Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))
        //
        let messageHash: Data = Data(hex: "aed54190962dce2c448391841fcd7730eb23ac18c5fa2a7896ac9074bf38f127")

        let preimagePrefix = "\u{19}Ethereum Signed Message:\n\(messageHash.count)"

        let preimage = preimagePrefix.data(using: .utf8)! + messageHash
        
        var signature = try key.sign(hash: EthHasher.hash(preimage))
        // make it safe signature encoding
        signature.v += 4
        
        print(signature.hexadecimal)
        // 0x8828432c415e8f6ea6fe37148d178aa37664d0e635954e6d32de7123ec49d4450164cc128094144e59d88bbb94242bbd9e3a4a90bcd6cc3b858eeb40a953ca7c20
        
        let pubKey = try EthereumPublicKey(
            message: preimage.makeBytes(),
            v: EthereumQuantity(quantity: BigUInt(signature.v) - 27 - 4),
            r: EthereumQuantity(signature.r.makeBytes()),
            s: EthereumQuantity(signature.s.makeBytes())
        )
        
        let address = pubKey.address.hex(eip55: true)
        print(address) // 0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0
    }
    
    func testGenerateFakeSignatureData() {
        // type 'contract signature' (0)
        let s = Data(repeating: 0xab, count: 32)
        
        let addr1: Sol.Address = "0x9F87C1aCaF3Afc6a5557c58284D9F8609470b571"
        
        let data1 = addr1.encode() + s + Data([0])
        
        print(data1.toHexStringWithPrefix())
        
        // type 'approved hash' (1)
        let addr2: Sol.Address = "0x9F7dfAb2222A473284205cdDF08a677726d786A0"
        let data2 = addr2.encode() + s + Data([1])
        print(data2.toHexStringWithPrefix())
    }
}
