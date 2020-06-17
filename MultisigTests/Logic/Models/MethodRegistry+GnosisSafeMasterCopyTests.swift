//
//  MethodRegistry+GnosisSafeMasterCopyTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 17.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class MethodRegistry_GnosisSafeMasterCopyTests: MethodRegistryTestCase {

    var validData: TransactionData!

    override func setUp() {
        super.setUp()
        validData = txData(
            ("valid changeMasterCopy()",
             "changeMasterCopy", [
                ("masterCopy", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66")
            ])
        )
    }

    func testChangeMasterCopyValid() {
        let call = MethodRegistry.GnosisSafeMasterCopy.ChangeMasterCopy(data: validData)
        XCTAssertEqual(call?.masterCopy, "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66")
    }

    func testChangeMasterCopyInvalidData() {
        let dataSet: [RawTxData] = [

            ("invalid method name",
             "___changeMasterCopy", [
                ("masterCopy", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66")
            ]),

            ("invalid address type",
             "changeMasterCopy", [
                ("masterCopy", "uint160", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66")
            ]),

            ("invalid address value",
             "changeMasterCopy", [
                ("masterCopy", "address", "some address")
            ]),

            ("missing params",
             "___changeMasterCopy", [
                // empty
            ]),

            ("too many params",
             "changeMasterCopy", [
                ("masterCopy", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("other", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66")
            ]),
        ]

        for data in dataSet {
            XCTAssertNil(MethodRegistry.GnosisSafeMasterCopy.ChangeMasterCopy(data: txData(data)), "Data: \(data)")
        }
    }

    func testIsValid() {
        let isValid = MethodRegistry.GnosisSafeMasterCopy.isValid
        let safe: AddressString = "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"
        let notSafe: AddressString = "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"

        let invalidData = txData(
            ("invalid method name",
             "___changeMasterCopy", [
                ("masterCopy", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66")
            ])
        )
        XCTAssertTrue(isValid(Transaction(
            safe: safe,
            to: safe,
            operation: .call,
            dataDecoded: validData)))

        XCTAssertFalse(isValid(Transaction(
            safe: safe,
            to: notSafe,
            operation: .call,
            dataDecoded: validData)))

        XCTAssertFalse(isValid(Transaction(
            safe: safe,
            to: nil,
            operation: .call,
            dataDecoded: validData)))

        XCTAssertFalse(isValid(Transaction(
            safe: nil,
            to: notSafe,
            operation: .call,
            dataDecoded: validData)))

        XCTAssertFalse(isValid(Transaction(
            safe: safe,
            to: safe,
            operation: .delegateCall,
            dataDecoded: validData)))

        XCTAssertFalse(isValid(Transaction(
            safe: safe,
            to: safe,
            operation: .call,
            dataDecoded: nil)))

        XCTAssertFalse(isValid(Transaction(
            safe: safe,
            to: notSafe,
            operation: .call,
            dataDecoded: invalidData)))
    }

}
