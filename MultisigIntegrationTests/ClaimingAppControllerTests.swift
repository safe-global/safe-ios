//
//  ClaimingAppControllerTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 22.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
import Solidity
@testable import Multisig

class ClaimingAppControllerTests: XCTestCase {
    let controller = ClaimingAppController()

    func test_isPaused() {
        let exp = expectation(description: "wait")

        _ = controller.isSafeTokenPaused { result in
            do {
                let isPaused = try result.get()
                XCTAssertTrue(isPaused)
            } catch {
                XCTFail("Failed: \(error)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_getVesting() {
        let exp = expectation(description: "wait")

        _ = controller.vesting(
            id: "0xb531d86add1d1e7febeb042d52d0eb0c49688ef4781dc8332bfab9a23c9307e7",
            contract: controller.configuration.userAirdrop,
            completion: { result in
                do {
                    let vesting = try result.get()
                    // unredeemed vesting is all zeroes
                    XCTAssertEqual(vesting.amount, 0)
                } catch {
                    XCTFail("Failed: \(error)")
                }
                exp.fulfill()
            })

        waitForExpectations(timeout: 10)
    }

    func test_isRedeemed() {
        let exp = expectation(description: "wait")

        _ = controller.isVestingRedeemed(
            hash: "0xb531d86add1d1e7febeb042d52d0eb0c49688ef4781dc8332bfab9a23c9307e7",
            contract: controller.configuration.userAirdrop,
            completion: { result in
                do {
                    let isRedeemed = try result.get()
                    XCTAssertFalse(isRedeemed)
                } catch {
                    XCTFail("Failed: \(error)")
                }
                exp.fulfill()
            })

        waitForExpectations(timeout: 10)
    }

    func test_getDelegate() {
        let exp = expectation(description: "wait")

        _ = controller.delegate(
            of: "0x25854e2a49a6cdaec7f0505b4179834509038549",
            completion: { result in
                do {
                    let delegate = try result.get()
                    XCTAssertEqual(delegate, 0)
                } catch {
                    XCTFail("Failed: \(error)")
                }
                exp.fulfill()
            })

        waitForExpectations(timeout: 10)
    }

    func test_getAllocations() {
        let exp = expectation(description: "wait")

        _ = controller.allocations(
            address: "0x1230B3d59858296A31053C1b8562Ecf89A2f888b",
            completion: { result in
                do {
                    let allocations = try result.get()
                    // NOTE: because of the error in the test data and because the vestings
                    // already deployed on rinkeby, we have 3 allocations for this test address
                    XCTAssertEqual(allocations.count, 3)
                    XCTAssertEqual(allocations.first?.amount, "5000110000000000000000")
                } catch {
                    XCTFail("Failed: \(error)")
                }
                exp.fulfill()
            })

        waitForExpectations(timeout: 10)
    }

    // delegate != nil → setDelegate(delegate)
    func test_claiming_setDelegate_address() {
        let transactions = controller.claimingTransactions(
            amount: 0,
            beneficiary: .zero,
            // given delegate is not nil
            delegate: "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            timestamp: 0,
            allocations: [],
            safeTokenPaused: false
        )

        guard let transaction = transactions.first else {
            XCTFail("Expected to find a transaction")
            return
        }

        XCTAssertEqual(transaction.to.address, Address(controller.configuration.delegateRegistry))
        XCTAssertEqual(
            transaction.data,
            DataString(hex:
                "0x" +
                // keccak(setDelegate(bytes32,address))[0..<4]
                "bd86e508" +
                // id: bytes32
                // == "safe.eth" utf8 bytes padded to bytes32
                "736166652e6574680000000000000000" +
                "00000000000000000000000000000000" +
                // delegate: address (encoded as uint160)
                "000000000000000000000000728cafe9" +
                "fb8cc2218fb12a9a2d9335193caa07e0"
            )
        )
    }

    // delegate == nil → no `setDelegate` transaction
    func test_claiming_setDelegate_nil() {
        let transactions = controller.claimingTransactions(
            amount: 0,
            beneficiary: .zero,
            delegate: nil,
            timestamp: 0,
            allocations: [],
            safeTokenPaused: false
        )
        XCTAssertTrue(transactions.isEmpty)
    }

    func test_claimingTransactions() throws {
        continueAfterFailure = false

        guard let fixture = try Fixture(filename: "claiming_test_fixtures.json") else {
            XCTFail("fixture not found")
            return
        }

        for testCase in fixture.testCases {
            print("Test: \(testCase.name)")

            let transactions = controller.claimingTransactions(
                amount: Sol.UInt128(testCase.amount)!,
                beneficiary: Address(testCase.beneficiary)!,
                delegate: testCase.delegate.flatMap { Address($0) },
                timestamp: testCase.timestamp,
                allocations: testCase.allocationInput,
                safeTokenPaused: testCase.safeTokenPaused)

            XCTAssertEqual(transactions.count, testCase.expectedTransactions.count, testCase.name)

            for (index, (tx, exp)) in zip(transactions, testCase.expectedTransactions).enumerated() {
                let infoText = "\(testCase.name): tx[\(index)]"
                XCTAssertEqual(tx.to, AddressString(exp.to)!, infoText)
                XCTAssertEqual(tx.data, DataString(exp.txData), infoText)
            }
        }
    }

    struct Fixture: Codable {
        var testCases: [TestCase]

        // each struct needs a conversion to the model struct

        struct TestCase: Codable {
            var name: String
            var amount: String
            var beneficiary: String
            var delegate: String?
            var timestamp: TimeInterval
            var allocations: [Allocation]
            var vestings: [Vesting]
            var safeTokenPaused: Bool
            var expectedTransactions: [ExpectedTransaction]

            var allocationInput: [(allocation: Multisig.Allocation, vesting: ClaimingAppController.Vesting)] {
                let allocationData: [Multisig.Allocation] = allocations.map { json in
                    return Multisig.Allocation(
                        account: AddressString(json.account)!,
                        chainId: json.chainID,
                        contract: AddressString(json.contract)!,
                        vestingId: DataString(hex: json.vestingID),
                        durationWeeks: json.durationWeeks,
                        startDate: json.startDate,
                        amount: UInt256String(UInt256(json.amount)!),
                        curve: json.curve,
                        proof: json.proof.map { DataString(hex: $0) }
                    )
                }
                let vestingData: [ClaimingAppController.Vesting] = vestings.map { json in
                    return ClaimingAppController.Vesting(
                        account: Sol.Address(hex: json.account)!,
                        curveType: Sol.UInt8(json.curveType),
                        managed: Sol.Bool(storage: json.managed),
                        durationWeeks: Sol.UInt16(json.durationWeeks),
                        startDate: Sol.UInt64(json.startDate),
                        amount: Sol.UInt128(json.amount)!,
                        amountClaimed: Sol.UInt128(json.amountClaimed)!,
                        pausingDate: Sol.UInt64(json.pausingDate),
                        cancelled: Sol.Bool(storage: json.cancelled)
                    )
                }
                let result = zip(allocationData, vestingData).map { $0 }
                return result
            }

            struct Allocation: Codable {
                var account: String
                var chainID: Int
                var contract: String
                var vestingID: String
                var durationWeeks: Int
                var startDate: UInt64
                var amount: String
                var curve: Int
                var proof: [String]

                enum CodingKeys: String, CodingKey {
                    case account
                    case chainID = "chainId"
                    case contract
                    case vestingID = "vestingId"
                    case durationWeeks, startDate, amount, curve, proof
                }
            }

            struct ExpectedTransaction: Codable {
                var to: String
                var data: String

                var txData: Data {
                    let lines = data.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n").map(String.init)
                    let bytes = lines.filter { !$0.hasPrefix("//") }
                    let hex = bytes.joined()
                    let result = Data(hex: hex)
                    return result
                }
            }

            struct Vesting: Codable {
                var account: String
                var curveType: Int
                var managed: Bool
                var durationWeeks: Int
                var startDate: Int
                var amount: String
                var amountClaimed: String
                var pausingDate: Int
                var cancelled: Bool
            }

        }
    }
}

extension ClaimingAppControllerTests.Fixture {
    init?(filename: String) throws {
        let name = filename.split(separator: ".").map(String.init)
        assert(name.count == 2)
        // load data from bundle
        guard let resource = Bundle(for: ClaimingAppControllerTests.self).url(forResource: name[0], withExtension: name[1]) else {
            return nil
        }
        let data = try Data(contentsOf: resource)
        self = try JSONDecoder().decode(Self.self, from: data)
        for t in testCases {
            assert(t.allocations.count == t.vestings.count, "allocation must match vesting")
        }
    }
}
