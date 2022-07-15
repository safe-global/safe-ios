//
//  CreatePasscodeFlowTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 08.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class CreatePasscodeFlowTests: UIIntegrationTestCase {

    // Given passcode is not set,
    // when create passcode flow starts,
    // then it shows 'create passcode' screen
    func test_showsCreatePasscode() {
        // 1. Given passcode is not set
        XCTAssertEqual(App.shared.auth.isPasscodeSetAndAvailable, false, "passcode must be not set")

        // 2. when create passcode flow starts,
        let flow = CreatePasscodeFlow(completion: { _ in })
        flow.modal(from: presenterVC)
        // wait for presentation animation to complete
        wait(timeout: 0.5)

        // 3. then it shows 'create passcode' screen
        let topScreen = topPresentedController()
        XCTAssertTrue(topScreen is CreatePasscodeViewController, "not a create passcode screen")
    }

}
