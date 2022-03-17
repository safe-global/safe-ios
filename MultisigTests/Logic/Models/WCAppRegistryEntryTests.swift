//
//  WCAppRegistryEntryTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 15.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
import WalletConnectSwift
@testable import Multisig

class WCAppRegistryEntryTests: XCTestCase {
    let wcUrl = WCURL(topic: "61f735f0-f883-48be-a366-7cf5fb53041a", version: "1", bridgeURL: URL(string: "https://bridge.example.com/")!, key: "453064f36ee552ed3b0be18df5d192240fa2b3c083d2ce5aa3a5e6b812ba77f2")
    let encodedUri = "wc%3A61f735f0%2Df883%2D48be%2Da366%2D7cf5fb53041a%401%3Fbridge%3Dhttps%253A%252F%252Fbridge%2Eexample%2Ecom%252F%26key%3D453064f36ee552ed3b0be18df5d192240fa2b3c083d2ce5aa3a5e6b812ba77f2"

    func universalLinkEntry(baseUri universalUri: String) -> WCAppRegistryEntry {
        let result = WCAppRegistryEntry(id: "1", role: .wallet, chains: ["1"], versions: ["1"], name: "wallet", rank: 0, linkMobileUniversal: URL(string: universalUri))
        return result
    }

    func deeplinkEntry(baseUri deeplinkUri: String) -> WCAppRegistryEntry {
        let result = WCAppRegistryEntry(id: "1", role: .wallet, chains: ["1"], versions: ["1"], name: "wallet", rank: 0, linkMobileNative: URL(string: deeplinkUri))
        return result
    }

    func testUniversalUri() {
        assertCorrectConnectUri(entry: universalLinkEntry(baseUri: "https://example.com"), expected: "https://example.com/wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: universalLinkEntry(baseUri: "https://example.com/"), expected: "https://example.com/wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: universalLinkEntry(baseUri: "https://example.com/app"), expected: "https://example.com/app/wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: (universalLinkEntry(baseUri: "https://example.com/path/to/app/")), expected: "https://example.com/path/to/app/wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: universalLinkEntry(baseUri: "https://example.com/wc"), expected: "https://example.com/wc?uri=\(encodedUri)")
    }

    func testDeeplinkUri() {
        assertCorrectConnectUri(entry: deeplinkEntry(baseUri: "example:"), expected: "example://wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: deeplinkEntry(baseUri: "example://"), expected: "example://wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: deeplinkEntry(baseUri: "example://wc"), expected: "example://wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: deeplinkEntry(baseUri: "example://app/wc"), expected: "example://app/wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: deeplinkEntry(baseUri: "example://path/to/app"), expected: "example://path/to/app/wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: deeplinkEntry(baseUri: "example"), expected: "example://wc?uri=\(encodedUri)")
        assertCorrectConnectUri(entry: deeplinkEntry(baseUri: "example/path"), expected: wcUrl.absoluteString)
    }

    func testNavigateUri() {
        assertCorrectNavigateUri(entry: universalLinkEntry(baseUri: "https://example.com"), expected: "https://example.com/wc?uri=wc:61f735f0-f883-48be-a366-7cf5fb53041a@1")
        assertCorrectNavigateUri(entry: deeplinkEntry(baseUri: "example:"), expected: "example://wc?uri=wc:61f735f0-f883-48be-a366-7cf5fb53041a@1")
    }

    func assertCorrectConnectUri(entry: WCAppRegistryEntry, expected: String, line: UInt = #line) {
        guard let link = entry.connectLink(from: WebConnectionURL(wcURL: wcUrl)) else {
            XCTFail("nil", line: line)
            return
        }

        XCTAssertEqual(link.absoluteString, expected, line: line)
    }

    func assertCorrectNavigateUri(entry: WCAppRegistryEntry, expected: String, line: UInt = #line) {
        guard let link = entry.navigateLink(from: WebConnectionURL(wcURL: wcUrl)) else {
            XCTFail("nil", line: line)
            return
        }

        XCTAssertEqual(link.absoluteString, expected, line: line)
    }
}
