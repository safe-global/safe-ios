//
//  WalletConnectManagerTests.swift
//  MultisigTests
//
//  Created by Dmitrii Bespalov on 02.02.24.
//  Copyright © 2024 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import WalletConnectSign

final class WalletConnectManagerTests: XCTestCase {
        // Test Variables:
    
        // reqNS: required namespace. Values: empty | irrelevant | relevant
        //      empty: empty value
        //      irrelevant: does not contain safe's chain
        //      relevant: contains safe's chain
    
        // optNS: optional namespace.
        
        // ID     reqNS        optNS       result
        //        -----------------------------------
        // 01     empty        empty       rejection
        // 02     empty        irrel       rejection
        // 03     empty        relev       approval with chains, accounts, methods, events of optNS
        // 04     irrel        empty       rejection
        // 05     irrel        irrel       rejection
        // 06     irrel        relev       approval with chains, accounts, methods, events of reqNS union optNS
        // 07     relev        empty       approval with chains, accounts, methods, events of reqNS
        // 08     relev        irrel       approval with ... of reqNS
        // 09     relev        relev       approval with ... of reqNS union optNS
    
    let safe = WalletConnectManager.Approver.Account(
        address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        chain: "42161"
    )
    
    func testApproveSession_01() throws {
        let proposal = try data("01_proposal").get(Session.Proposal.self)
        WalletConnectManager.shared.approver = TestRejecter(proposal: proposal, testSafe: safe)
        WalletConnectManager.shared.approveSession(proposal: proposal)
    }
    
    func testApproveSession_02() throws {
        let proposal = try data("02_proposal").get(Session.Proposal.self)
        WalletConnectManager.shared.approver = TestRejecter(proposal: proposal, testSafe: safe)
        WalletConnectManager.shared.approveSession(proposal: proposal)
    }
    
    func testApproveSession_03() throws {
        let proposal = try data("03_proposal").get(Session.Proposal.self)
        let approval = try data("03_approval").get([String: SessionNamespace].self)
        WalletConnectManager.shared.approver = TestApprover(proposal: proposal, approval: approval, testSafe: safe)
        WalletConnectManager.shared.approveSession(proposal: proposal)
    }
    
    func testApproveSession_04() throws {
        let proposal = try data("04_proposal").get(Session.Proposal.self)
        WalletConnectManager.shared.approver = TestRejecter(proposal: proposal, testSafe: safe)
        WalletConnectManager.shared.approveSession(proposal: proposal)
    }
    
    func testApproveSession_05() throws {
        let proposal = try data("05_proposal").get(Session.Proposal.self)
        WalletConnectManager.shared.approver = TestRejecter(proposal: proposal, testSafe: safe)
        WalletConnectManager.shared.approveSession(proposal: proposal)
    }
        
    func testApproveSession_06() throws {
        let proposal = try data("06_proposal").get(Session.Proposal.self)
        let approval = try data("06_approval").get([String: SessionNamespace].self)
        WalletConnectManager.shared.approver = TestApprover(proposal: proposal, approval: approval, testSafe: safe)
        WalletConnectManager.shared.approveSession(proposal: proposal)
    }
    
    func testApproveSession_07() throws {
        let proposal = try data("07_proposal").get(Session.Proposal.self)
        let approval = try data("07_approval").get([String: SessionNamespace].self)
        WalletConnectManager.shared.approver = TestApprover(proposal: proposal, approval: approval, testSafe: safe)
        WalletConnectManager.shared.approveSession(proposal: proposal)
    }
    
    func testApproveSession_08() throws {
        let proposal = try data("08_proposal").get(Session.Proposal.self)
        let approval = try data("08_approval").get([String: SessionNamespace].self)
        WalletConnectManager.shared.approver = TestApprover(proposal: proposal, approval: approval, testSafe: safe)
        WalletConnectManager.shared.approveSession(proposal: proposal)
    }
    
    func testApproveSession_09() throws {
        let proposal = try data("09_proposal").get(Session.Proposal.self)
        let approval = try data("09_approval").get([String: SessionNamespace].self)
        WalletConnectManager.shared.approver = TestApprover(proposal: proposal, approval: approval, testSafe: safe)
        WalletConnectManager.shared.approveSession(proposal: proposal)
    }
    
    class TestApprover: WalletConnectManager.Approver {
        internal init(proposal: Session.Proposal, approval: [String : SessionNamespace], testSafe: Account) {
            self.proposal = proposal
            self.approval = approval
            self.testSafe = testSafe
        }
        
        var proposal: Session.Proposal
        var approval: [String: SessionNamespace]
        var testSafe: Account
        
        override var safe: WalletConnectManager.Approver.Account? {
            testSafe
        }
        
        override func approve(proposalId: String, namespaces: [String : SessionNamespace]) {
            XCTAssertEqual(proposalId, proposal.id)
            XCTAssertEqual(namespaces, approval)
        }
        
        override func reject(_ failure: WalletConnectManager.Approver.ApprovalFailure) {
            XCTFail("Unexpected reject: \(failure)")
        }
    }
    
    class TestRejecter: WalletConnectManager.Approver {
        internal init(proposal: Session.Proposal, testSafe: WalletConnectManager.Approver.Account) {
            self.proposal = proposal
            self.testSafe = testSafe
        }
        
        var proposal: Session.Proposal
        var testSafe: Account

        override var safe: WalletConnectManager.Approver.Account? {
            testSafe
        }

        override func approve(proposalId: String, namespaces: [String : SessionNamespace]) {
            XCTFail("Unexpected approve: \(proposalId) \(namespaces)")
        }
        
        override func reject(_ failure: WalletConnectManager.Approver.ApprovalFailure) {
            XCTAssertEqual(failure, .chainNotFound(id: proposal.id))
        }
    }
    
    func data(_ name: String) throws -> AnyCodable {
        let resource = Bundle(for: WalletConnectManagerTests.self)
            .url(forResource: name, withExtension: "json", subdirectory: "WalletConnectManagerTestData.bundle")

        guard let url = resource else {
            XCTFail("Test data not found: \(name)")
            return AnyCodable(any: "")
        }

        let data = try Data(contentsOf: url)
        let result = try JSONDecoder().decode(AnyCodable.self, from: data)
        return result
    }
}
