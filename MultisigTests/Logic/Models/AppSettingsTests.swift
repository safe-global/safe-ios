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
        XCTAssertFalse(AppSettings.termsAccepted)
        AppSettings.termsAccepted = true
        XCTAssertTrue(AppSettings.termsAccepted)

        XCTAssertFalse(AppSettings.hasShownImportKeyOnboarding)
        AppSettings.hasShownImportKeyOnboarding = true
        XCTAssertTrue(AppSettings.hasShownImportKeyOnboarding)

        XCTAssertFalse(AppSettings.importKeyBannerDismissed)
        AppSettings.importKeyBannerDismissed = true
        XCTAssertTrue(AppSettings.importKeyBannerDismissed)

        XCTAssertFalse(AppSettings.importedOwnerKey)
        AppSettings.importedOwnerKey = true
        XCTAssertTrue(AppSettings.importedOwnerKey)

    }
}
