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
        createAppSettings(selectedSafe: "one")
        createAppSettings(selectedSafe: "two")
        let result = try context.fetch(AppSettings.settings())
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].selectedSafe, "one")
    }

    private func createAppSettings(selectedSafe: String?) {
        let appSettings = AppSettings(context: context)
        appSettings.selectedSafe = selectedSafe
    }
}
