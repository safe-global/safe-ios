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

    // case 3.1:
        // claimed amount: 100
        // safe token: paused
        // user airdrop: not redeemed
        // user airdrop available to claim: 1000000000000330000000
        // ecosystem airdrop: not eligible
        // delegate: not set
    // expected transactions:
        // Delegate Registry . setDelegate ( new delegate )
        // User Airdrop .  redeem()
        // User Airdrop . claimVestedTokensViaModule( 100 )
    func test_claimPartialUserAirdrop() throws {
        continueAfterFailure = false

        let allocation = try JSONDecoder().decode([Allocation].self, from: Data(contentsOf: Bundle(for: Self.self).url(forResource: "0x000543D851CD52a6bFD83a1D168D35DeAE4E3590", withExtension: "json")!))[0]

        let transactions = controller.claimingTransactions(
            amount: 100,
            beneficiary: "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            delegate: "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0",
            timestamp: 1531555200 + 416 * 7 * 24 * 60 * 60,
            allocations: [
                (allocation: allocation,
                 // not redeemed vesting == not initialized (all values are zeroes)
                 vesting: ClaimingAppController.Vesting(
                    account: 0,
                    curveType: 0,
                    managed: false,
                    durationWeeks: 0,
                    startDate: 0,
                    amount: 0,
                    amountClaimed: 0,
                    pausingDate: 0,
                    cancelled: false))
            ],
            safeTokenPaused: true)

        XCTAssertEqual(transactions.count, 3, "Unexpected number of transactions")

        // Delegate Registry . setDelegate ( new delegate )
        XCTAssertEqual(transactions[0].to, "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0")
        XCTAssertEqual(
            transactions[0].data,
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

        // User Airdrop .  redeem()
        XCTAssertEqual(transactions[1].to, AddressString(controller.configuration.userAirdrop))
        XCTAssertEqual(
            transactions[1].data,
            DataString(hex:
                       "0x" +
                       // keccak(redeem(uint8,uint16,uint64,uint128,bytes32[])[0..<4]
                       "bf6213e4" +
                       // curveType (uint8) = 0
                       "0000000000000000000000000000000000000000000000000000000000000000" +
                       // durationWeeks (uint16) = 416 = 0x1A0
                       "00000000000000000000000000000000000000000000000000000000000001a0" +
                       // startDate (uint64) = 1531555200 = 0x5B49AD80
                       "000000000000000000000000000000000000000000000000000000005b49ad80" +
                       // amount (uint128) = 1000000000000330000000 = 3635c9adc5f24b6680
                       "00000000000000000000000000000000000000000000003635c9adc5f24b6680" +
                       // proof (bytes32[]). Offset from the start of data to the location of array a0 = 160 bytes = 5 * 32
                       "00000000000000000000000000000000000000000000000000000000000000a0" +
                       // size of the bytes32[] array: f = 15
                       "000000000000000000000000000000000000000000000000000000000000000f" +
                       // element at index 0
                       "8effecbcd044908bbccc482418326488b5692c0b2f3dffb918613f672539171c" +
                       "773a5c3647e7086a1b52dcb8004a0ce268fbe331908c3ce1923252295774c21d" +
                       "67e85f675b36971bcbf75135284a12246448ebc19d8ade9220247668d16f9b43" +
                       "6af4f34ceaedd0344b3cc1e0e0237b1158ebff6bcc76c330b5e0fd2126288899" +
                       "287bd2b030eadd62bfd9f20600243a23ba2e033f6dc8e3b88dc67acf32658aa2" +
                       "70f11763035e0b6c0a14e92a8d9b024e276aab3413bdc17b8a2fc4276a56e44b" +
                       "d99fbb1dbbb3fefb91a0358da324edd045d3f00ba38edf71f69da9a3b0c394f4" +
                       "e334230a9d71a37d1b1c6f03a7182ddaba4eaaf8a6b449fde1bb2c6422c6588e" +
                       "3189cc25e4217d7bf4f788bd16698a9e8137f74051d5a8c6a608e9888e4e585a" +
                       "50168d345960483668006659313366324315aff37d2bb0af6de40d67e16ea00b" +
                       "9a91efd8095f6a828d24f0476ba3aa09864ae8f14a0e6dffae6109d73fb04c51" +
                       "60a9debe7b1ad678911a5a0c8f9e00a60f2c0e930024f70baa52be7971057f75" +
                       "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470" +
                       "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470" +
                       // element at index 14
                       "63af4e18eb6e2998d99d03dada6c02d844efe3a3a449adc76ccfafd12c7aacf2"
                      )
        )

        // User Airdrop . claimVestedTokensViaModule( 100 )
        XCTAssertEqual(transactions[2].to, AddressString(controller.configuration.userAirdrop))
        XCTAssertEqual(
            transactions[1].data,
            DataString(hex:
                       "0x" +
                       // keccak(claimVestedTokensViaModule(bytes32,address,uint128))[0..<4]
                       "0087b83f" +
                       // vestingId (bytes32) = 0x9eb40c52b1c6e36b1f7af3f361f326601aca4831262a28f219d2cd6f79e0e9aa
                       "9eb40c52b1c6e36b1f7af3f361f326601aca4831262a28f219d2cd6f79e0e9aa" +
                       // beneficiary (address) = 0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0
                       "000000000000000000000000728cafe9fb8cc2218fb12a9a2d9335193caa07e0" +
                       // tokensToClaim (uint128) = 100 = 0x64
                       "0000000000000000000000000000000000000000000000000000000000000064"
                      )
        )
    }
}
