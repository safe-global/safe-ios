//
//  AppSettingsTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 29.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class AppSettingsTests: CoreDataTestCase {
    func test_appSettings() {
        XCTAssertFalse(AppSettings.hasAcceptedTerms())
        AppSettings.acceptTerms()
        XCTAssertTrue(AppSettings.hasAcceptedTerms())
    }
}
