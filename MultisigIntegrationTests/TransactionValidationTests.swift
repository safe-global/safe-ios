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
    
    
    // test cases
    
    // prereqs:
    // status == awaiting
    // safe.owners.count > 0
    // safe.version is there
    // safe.chain.id is there
    // can convert tx to Transaction
    // tx has multisig info
    
    // safeTxHash is correctly computed from properties -> invalid safeTxHash!
    // confirmations.count == 0 -> no confirmations!
    // confirmations not subset of owners -> not owners!
    // one confirmation - must be a valid confirmation -> not owner!
    // multiple confirmations - all must be valid confirmations, i.e. match the address -> not owner!
        // just one invalid -> warning
        // all invalid -> warning
    // types for contract version >= 1.1.0
        // confirmation type = contract signature
        // confirmation type = approvedHash
        // confirmation type = eth_sign
        // confirmation type = ecdsa
    // types for contract version 1.1.0
        // confirmation type = contract signature
        // confirmation type = approvedHash
        // confirmation type = ecdsa
    
    func testTransactions() throws {
        try validateTransactionCase("TransactionValidationTestCase1")
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
        
        XCTAssertNoThrow(
            try builder.validate(tx: testCase.tx, safe: safe)
        )
    }
    
}
