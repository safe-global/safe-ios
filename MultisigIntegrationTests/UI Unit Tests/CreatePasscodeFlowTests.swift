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

    // Given passcode is set,
    // when create passcode flow starts,
    // then it doesn't show anything

    // Given passcode is not set
    // and create passcode flow started
    // when user enters passcode
    // then "repeat passcode" screen shown

    // Given passcode is not set
    // and create passcode flow started
    // when user skips creating passcode
    // then the flow closed

    // Given passcode is not set
    // and create passcode flow started
    // when user swipes down
    // then the flow is closed

    // Given repeat passcode is shown
    // when user taps back
    // then goes back to create passcode

    // Given repeat passcode is shown
    // when user taps skip
    // then flow is closed

    // Given repeat passcode is shown
    // when user enters the correct passcode
    // then flow completed with success

}

// create passcode screen
    // enter 3 digits, erase one digit

// repeat passcode
    // enter 3 digits, erase
    // enter 6 digits, all different
    // enter 6 digits, 5 same, 1 different
