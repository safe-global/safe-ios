//
//  MethodRegistry+ERC20Tests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 17.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class MethodRegistry_ERC20Tests: MethodRegistryTestCase {

    var validTransferData: TransactionData!
    var validTransferFromData: TransactionData!

    override func setUp() {
        super.setUp()
        validTransferData = txData((
            "valid transfer() data",
            "transfer", [
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "uint256", "1")]))

        validTransferFromData = txData((
        "valid transferFrom() data",
        "transferFrom", [
            ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
            ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
            ("value", "uint256", "3")]))
    }

    func testTransferValidInputs() {
        let call = MethodRegistry.ERC20.Transfer(data: validTransferData)
        XCTAssertEqual(call?.to, "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488")
        XCTAssertEqual(call?.amount, 1)
    }

    func testTransferFromValidInputs() {
        let call = MethodRegistry.ERC20.TransferFrom(data: validTransferFromData)
        XCTAssertEqual(call?.from, "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66")
        XCTAssertEqual(call?.to, "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488")
        XCTAssertEqual(call?.amount, 3)
    }

    func testTransferInvalidInputs() {
        let dataSet: [RawTxData] = [
            ("invalid method name",
             "transfer123", [
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "uint256", "1") ]),

            ("invalid address value",
             "transfer", [
                ("to", "address", "invalid addres"),
                ("value", "uint256", "1") ]),

            ("invalid address's type",
             "transfer", [
                ("to", "address_???", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "uint256", "1") ]),

            ("invalid amount type",
             "transfer", [
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "xxx", "1") ]),

            ("invalid amount value",
             "transfer", [
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "uint256", "some value") ]),

            ("less arguments than needed",
             "transfer", [
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488") ]),

            ("more arguments than needed",
             "transfer", [
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "uint256", "1"),
                ("value2", "uint256", "2") ]),
        ]

        for data in dataSet {
            XCTAssertNil(MethodRegistry.ERC20.Transfer(data: txData(data)), "Data: \(data)")
        }
    }

    func testTransferFromInvalidInputs() {
        let dataSet: [RawTxData] = [

            ("invalid method name",
             "transferFrom123", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "uint256", "1") ]),

            ("invalid first address value",
             "transferFrom", [
                ("from", "address", "invalid addres"),
                ("to", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("value", "uint256", "1") ]),

            ("invalid rist addess's type",
             "transferFrom", [
                ("from", "address_???", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("to", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("value", "uint256", "1") ]),

            ("invalid second address value",
             "transferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "invalid addres"),
                ("value", "uint256", "1") ]),

            ("invalid second addess's type",
             "transferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address_???", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "uint256", "1") ]),

            ("invalid amount type",
             "transferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "xxx", "1") ]),

            ("invalid amount value",
             "transferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "uint256", "some value") ]),

            ("less arguments than needed",
             "transferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488") ]),

            ("more arguments than needed",
             "transferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("value", "uint256", "1"),
                ("value2", "uint256", "2") ]),
        ]

        for data in dataSet {
            XCTAssertNil(MethodRegistry.ERC20.TransferFrom(data: txData(data)), "Data: \(data)")
        }
    }

}
