//
//  MethodRegistry+ERC721Tests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 17.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class MethodRegistry_ERC721Tests: MethodRegistryTestCase {

    var validSafeTransferFromData: TransactionData!
    var validSafeTransferFromDataData: TransactionData!

    override func setUp() {
        super.setUp()
        validSafeTransferFromData = txData((
        "valid safeTransferFrom() data",
        "safeTransferFrom", [
            ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
            ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
            ("tokenId", "uint256", "3")]))

        validSafeTransferFromDataData = txData((
        "valid safeTransferFrom() data",
        "safeTransferFrom", [
            ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
            ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
            ("tokenId", "uint256", "3"),
            ("data", "bytes", "0x12345670")
        ]))

    }

    func testSafeTransferFromValidInputs() {
        let call = MethodRegistry.ERC721.SafeTransferFrom(data: validSafeTransferFromData)
        XCTAssertEqual(call?.from, "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66")
        XCTAssertEqual(call?.to, "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488")
        XCTAssertEqual(call?.tokenId, 3)
    }

    func testSafeTransferFromDataValidInputs() {
        let call = MethodRegistry.ERC721.SafeTransferFromData(data: validSafeTransferFromDataData)
        XCTAssertEqual(call?.from, "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66")
        XCTAssertEqual(call?.to, "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488")
        XCTAssertEqual(call?.tokenId, 3)
        XCTAssertEqual(call?.data, Data(hex: "0x12345670"))
    }
    func testSafeTransferFromInvalidInputs() {
        let dataSet: [RawTxData] = [

            ("invalid method name",
             "safeTransferFrom123", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "uint256", "1") ]),

            ("invalid first address value",
             "safeTransferFrom", [
                ("from", "address", "invalid addres"),
                ("to", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("tokenId", "uint256", "1") ]),

            ("invalid rist addess's type",
             "safeTransferFrom", [
                ("from", "address_???", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("to", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("tokenId", "uint256", "1") ]),

            ("invalid second address value",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "invalid addres"),
                ("tokenId", "uint256", "1") ]),

            ("invalid second addess's type",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address_???", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "uint256", "1") ]),

            ("invalid amount type",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "xxx", "1") ]),

            ("invalid amount value",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "uint256", "some value") ]),

            ("less arguments than needed",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488") ]),

            ("more arguments than needed",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "uint256", "1"),
                ("tokenId2", "uint256", "2") ]),
        ]

        for data in dataSet {
            XCTAssertNil(MethodRegistry.ERC721.SafeTransferFrom(data: txData(data)), "Data: \(data)")
        }
    }

    func testSafeTransferFromDataInvalidInputs() {
        let dataSet: [RawTxData] = [

            ("invalid method name",
             "safeTransferFrom123", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "uint256", "1"),
                ("data", "bytes", "0x1234") ]),

            ("invalid first address value",
             "safeTransferFrom", [
                ("from", "address", "invalid addres"),
                ("to", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("tokenId", "uint256", "1"),
                ("data", "bytes", "0x1234") ]),

            ("invalid rist addess's type",
             "safeTransferFrom", [
                ("from", "address_???", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("to", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("tokenId", "uint256", "1"),
                ("data", "bytes", "0x1234") ]),

            ("invalid second address value",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "invalid addres"),
                ("tokenId", "uint256", "1"),
                ("data", "bytes", "0x1234") ]),

            ("invalid second addess's type",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address_???", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "uint256", "1"),
                ("data", "bytes", "0x1234") ]),

            ("invalid amount type",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "xxx", "1"),
                ("data", "bytes", "0x1234") ]),

            ("invalid amount value",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "uint256", "some value"),
                ("data", "bytes", "0x1234") ]),

            ("invalid data type",
            "safeTransferFrom", [
               ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
               ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
               ("tokenId", "uint256", "1"),
               ("data", "xxx", "0x1234") ]),

            ("invalid data value",
            "safeTransferFrom", [
               ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
               ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
               ("tokenId", "uint256", "1"),
               ("data", "bytes", "0xinvalid value") ]),

            ("less arguments than needed",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488") ]),

            ("more arguments than needed",
             "safeTransferFrom", [
                ("from", "address", "0xaD86EecCbaC5e47848649936cf1efE78D56b1F66"),
                ("to", "address", "0x37d037a9b66a323fBD38E9e2ae65e04C7C049488"),
                ("tokenId", "uint256", "1"),
                ("data", "bytes", "0x1234"),
                ("tokenId2", "uint256", "2") ]),
        ]

        for data in dataSet {
            XCTAssertNil(MethodRegistry.ERC721.SafeTransferFromData(data: txData(data)), "Data: \(data)")
        }
    }

    func testIsValidTransfer() {
        XCTAssertTrue(MethodRegistry.ERC721.isValid(Transaction(operation: .call, dataDecoded: validSafeTransferFromData)))
        XCTAssertTrue(MethodRegistry.ERC721.isValid(Transaction(operation: .call, dataDecoded: validSafeTransferFromDataData)))
        XCTAssertFalse(MethodRegistry.ERC721.isValid(Transaction(operation: .delegateCall, dataDecoded: validSafeTransferFromData)))
        XCTAssertFalse(MethodRegistry.ERC721.isValid(Transaction(operation: .call, dataDecoded: nil)))
    }

}
