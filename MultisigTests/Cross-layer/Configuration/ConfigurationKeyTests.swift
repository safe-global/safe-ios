//
//  ConfigurationKeyTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 27.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class ConfigurationKeyTests: XCTestCase {

    func test_bundleKeys() {
        struct Config {
            @ConfigurationKey("CFBundleIdentifier")
            var bundleID: String

            @ConfigurationKey("CFBundleDisplayName")
            var appName: String

            @ConfigurationKey("CFBundleShortVersionString")
            var marketingVersion: String

            @ConfigurationKey("CFBundleVersion")
            var buildVersion: String
        }

        var config = Config()
        // should not crash the tests
        XCTAssertNotNil(config.bundleID)
        XCTAssertNotNil(config.appName)
        XCTAssertNotNil(config.marketingVersion)
        XCTAssertNotNil(config.buildVersion)

        // overriding
        config.appName = "My App Name"
        XCTAssertEqual(config.appName, "My App Name")
    }

}
