//
//  OwnerKeySelectionPolicyTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 13.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import Solidity

class OwnerKeySelectionPolicyTests: XCTestCase {
    let policy = OwnerKeySelectionPolicy()

    typealias Candidate = OwnerKeySelectionPolicy.KeyCandidate


    func testKeyCandidateEquatable() {
        let a = Candidate(key: KeyInfo())
        XCTAssertEqual(a, a)
        let b = Candidate(key: KeyInfo())
        XCTAssertNotEqual(a, b)
    }

    func testEmpty() {
        XCTAssertNil(policy.defaultExecutionKey(in: []))
    }

    func testOneElement() {
        let one = [Candidate(key: KeyInfo())]
        XCTAssertEqual(policy.defaultExecutionKey(in: one), one[0])
    }

    // var1: owner/non-owner = t/f
    // var2: balance >= requiredAmount = t/f

    // var1    var2     result
    // T        T       owner with the highest balance
    // T        F       non-owner with the highest balance
    // F        T       non-owner with the highest balance
    // F        F       owner with highest balance (or if empty non owner with highest balance
    func testOwnerWithEnoughBalance() {
        let requiredAmount: Sol.UInt256 = 10
        let winnerIsOnwerWithEnoughBalance = Candidate(key: KeyInfo(), balance: 10, isOwner: true)
        let input = [
            Candidate(key: KeyInfo(), balance: 10, isOwner: false),
            Candidate(key: KeyInfo(), balance: 1, isOwner: true),
            Candidate(key: KeyInfo(), balance: 2, isOwner: true),
            winnerIsOnwerWithEnoughBalance,
            Candidate(key: KeyInfo(), balance: 1, isOwner: false),
            Candidate(key: KeyInfo(), balance: 2, isOwner: false),
        ]
        let result = policy.defaultExecutionKey(in: input, requiredAmount: requiredAmount)
        XCTAssertEqual(result, winnerIsOnwerWithEnoughBalance)
    }

    func testOwnerWithNotEnoughBalance() {
        let requiredAmount: Sol.UInt256 = 10
        let winnerIsNonOwnerWithEnoughBalance = Candidate(key: KeyInfo(), balance: 10, isOwner: false)
        let input = [
            winnerIsNonOwnerWithEnoughBalance,
            Candidate(key: KeyInfo(), balance: 1, isOwner: true),
            Candidate(key: KeyInfo(), balance: 2, isOwner: true),
            Candidate(key: KeyInfo(), balance: 9, isOwner: true),
            Candidate(key: KeyInfo(), balance: 1, isOwner: false),
            Candidate(key: KeyInfo(), balance: 2, isOwner: false),
        ]
        let result = policy.defaultExecutionKey(in: input, requiredAmount: requiredAmount)
        XCTAssertEqual(result, winnerIsNonOwnerWithEnoughBalance)
    }

    func testWithNotEnoughBalance() {
        let requiredAmount: Sol.UInt256 = 10
        let winnerIsOwnerWithHighestBalance = Candidate(key: KeyInfo(), balance: 8, isOwner: true)
        let input = [
            Candidate(key: KeyInfo(), balance: 9, isOwner: false),
            Candidate(key: KeyInfo(), balance: 1, isOwner: true),
            Candidate(key: KeyInfo(), balance: 2, isOwner: true),
            winnerIsOwnerWithHighestBalance,
            Candidate(key: KeyInfo(), balance: 1, isOwner: false),
            Candidate(key: KeyInfo(), balance: 2, isOwner: false),
        ]
        let result = policy.defaultExecutionKey(in: input, requiredAmount: requiredAmount)
        XCTAssertEqual(result, winnerIsOwnerWithHighestBalance)
    }

    func testNoNonOwnersAtAllAndWithNotEnoughBalance() {
        let requiredAmount: Sol.UInt256 = 10
        let winnerIsWithHighestBalance = Candidate(key: KeyInfo(), balance: 9, isOwner: true)
        let input = [
            Candidate(key: KeyInfo(), balance: 1, isOwner: true),
            winnerIsWithHighestBalance,
            Candidate(key: KeyInfo(), balance: 2, isOwner: true),
        ]
        let result = policy.defaultExecutionKey(in: input, requiredAmount: requiredAmount)
        XCTAssertEqual(result, winnerIsWithHighestBalance)
    }

    func testNoOwnersAtAllAndWithNotEnoughBalance() {
        let requiredAmount: Sol.UInt256 = 10
        let winnerIsWithHighestBalance = Candidate(key: KeyInfo(), balance: 9, isOwner: false)
        let input = [
            Candidate(key: KeyInfo(), balance: 1, isOwner: false),
            winnerIsWithHighestBalance,
            Candidate(key: KeyInfo(), balance: 2, isOwner: false),
        ]
        let result = policy.defaultExecutionKey(in: input, requiredAmount: requiredAmount)
        XCTAssertEqual(result, winnerIsWithHighestBalance)
    }
}
