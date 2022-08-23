//
//  ClaimingAppControllerTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 22.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
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
}
