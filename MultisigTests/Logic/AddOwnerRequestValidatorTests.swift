//
//  AddOwnerRequestValidatorTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 14.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

// Format change needs tests updated
class AddOwnerRequestValidatorTests: XCTestCase {
    let domain = "app.safe.global"

    override func setUp() async throws {
        AddOwnerRequestValidator.webAppURL = URL(string: "https://\(domain)/")!
    }

    func testAddOwnerRequestUrls() {
        
        assertInvalid("https://\(domain)", "missing path and query")
        assertInvalid("ftp://url?query=https://\(domain)/", "must start with the correct link")
        assertInvalid("https://\(domain)/", "missing rest of the path and query")
        assertInvalid("https://\(domain)/addOwner?safe=something&address=else", "wrong format of path and query parameters")
        assertInvalid("https://\(domain)/eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A/addOwner", "missing owner address query parameter")

        // shortname with dash
        assertValid("https://\(domain)/addOwner?safe=eth-weth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "must support dash in shortname")

        // shortname empty, 1, 20, 21
        assertValid("https://\(domain)/addOwner?safe=a:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "must support one-char shortname")
        assertValid("https://\(domain)/addOwner?safe=abcde12345abcde12345:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "must support 20-char shortname")
        assertInvalid("https://\(domain)/addOwner?safe=abcde12345abcde12345e:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "shortname too long")
        assertInvalid("https://\(domain)/addOwner?safe=:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "shortname empty")

        // safe address: empty, 39, 40, 41, hex, checksum wrong
        assertInvalid("https://\(domain)/addOwner?safe=eth:&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "safe address empty")
        assertInvalid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "safe address too short")
        assertInvalid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A1&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "safe address too long")
        assertValid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "must support hex safe address")
        assertInvalid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041f8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "must detect wrong checksum in safe address")

        // owner address: empty, 39, 40, 41, hex, checksum wrong
        assertInvalid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=", "owner address empty")
        assertInvalid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b6", "owner address too short")
        assertInvalid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66a", "owner address too long")
        assertValid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6a5adb2b88257a3dac7a76a7b4ecacda090b66", "must support hex owner address")
        assertInvalid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090B66", "must detect wrong checksum in owner address")

        // additional params
        assertInvalid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66&some=value", "happy case not working")


        // happy case
        assertValid("https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66", "happy case not working")
    }

    func testExtractsParameters() {
        let url = URL(string: "https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66")!
        guard let parameters = AddOwnerRequestValidator.parameters(from: url) else {
            XCTFail("Parameters not found in correct link")
            return
        }

        XCTAssertEqual(parameters.chain.shortName, "eth")
        XCTAssertEqual(parameters.safeAddress, "0x71592E6Cbe7779D480C1D029e70904041F8f602A")
        XCTAssertEqual(parameters.ownerAddress, "0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66")
    }
    
    func testLink() {        
        let str = AddOwnerRequestParameters(
            chain: .mainnetChain(),
            safeAddress: "0x71592E6Cbe7779D480C1D029e70904041F8f602A",
            ownerAddress: "0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66"
        ).link(base: AddOwnerRequestValidator.webAppURL)
        
        XCTAssertEqual(str, "https://\(domain)/addOwner?safe=eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A&address=0x8e6A5aDb2B88257A3DAc7A76A7B4EcaCdA090b66")
    }

    func assertInvalid(_ str: String, _ message: String, line: UInt = #line) {
        guard let url = URL(string: str) else {
            XCTFail("Not a url", line: line)
            return
        }
        XCTAssertFalse(AddOwnerRequestValidator.isValid(url: url), message, line: line)
    }

    func assertValid(_ str: String, _ message: String, line: UInt = #line) {
        guard let url = URL(string: str) else {
            XCTFail("Not a url", line: line)
            return
        }
        XCTAssertTrue(AddOwnerRequestValidator.isValid(url: url), message, line: line)
    }
}
