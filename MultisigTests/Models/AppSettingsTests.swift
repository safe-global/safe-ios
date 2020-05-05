//
//  AppSettingsTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 21.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class AppSettingsTests: CoreDataTestCase {
    func test_settings_alwaysReturnsLastRecord() throws {
        let safe1 = Safe(context: context)
        safe1.name = "one"
        let safe2 = Safe(context: context)
        safe2.name = "two"
        createAppSettings(safe: safe1)
        createAppSettings(safe: safe2)
        let result = try context.fetch(AppSettings.settings())
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].selectedSafe, safe1)
    }

    private func createAppSettings(safe: Safe?) {
        let appSettings = AppSettings(context: context)
        appSettings.selectedSafe = safe
    }
}
