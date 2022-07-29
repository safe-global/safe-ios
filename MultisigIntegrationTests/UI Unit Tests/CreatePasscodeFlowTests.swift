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
    var keychainService: SecureStore!
    let animationDuration: TimeInterval = 0.5

    override func setUpWithError() throws {
        try super.setUpWithError()
        keychainService = KeychainService(identifier: "KeychainIntegrationTest \(name)")
        App.shared.keychainService = keychainService
    }

    // Given passcode is not set,
    // when create passcode flow starts modally,
    // then it shows 'create passcode' screen
    func test_showsCreatePasscode_modal() {
        // 1. Given passcode is not set
        XCTAssertEqual(App.shared.auth.isPasscodeSetAndAvailable, false, "passcode must be not set")

        // 2. when create passcode flow starts,
        _ = startModalCreatePasscodeFlow()

        // 3. then it shows 'create passcode' screen
        let topScreen = topPresentedController()
        XCTAssertTrue(topScreen is CreatePasscodeViewController, "not a create passcode screen")
    }

    // Given passcode is not set,
    // when create passcode flow starts from existing navigation stack,
    // then it shows 'create passcode' screen
    func test_showsCreatePasscode_push() {
        // 1. Given passcode is not set
        XCTAssertEqual(App.shared.auth.isPasscodeSetAndAvailable, false, "passcode must be not set")

        // 2. when create passcode flow starts,
        _ = pushCreatePasscodeFlow()

        // 3. then it shows 'create passcode' screen
        let topScreen = topPresentedController()
        XCTAssertTrue(topScreen is CreatePasscodeViewController, "not a create passcode screen")
    }

    // Given passcode is set,
    // when create passcode flow starts modally,
    // then it doesn't show anything
    func test_doesntShowCreatePasscode_modal() throws {
        // Given passcode is set,
        try App.shared.auth.createPasscode(plaintextPasscode: "123456")
        XCTAssertEqual(App.shared.auth.isPasscodeSetAndAvailable, true, "passcode must be set")

        // when create passcode flow starts,
        let _ = startModalCreatePasscodeFlow()

        // then it doesn't show anything
        XCTAssertNil(presentedController, "expected that nothing is presented")
    }

    // Given passcode is set,
    // when create passcode flow starts from existing navigation stack,
    // then it doesn't show anything
    func test_doesntShowCreatePasscode_push() throws {
        // Given passcode is set,
        try App.shared.auth.createPasscode(plaintextPasscode: "123456")
        XCTAssertEqual(App.shared.auth.isPasscodeSetAndAvailable, true, "passcode must be set")

        // when create passcode flow starts,
        _ = pushCreatePasscodeFlow()

        // then it doesn't show anything
        XCTAssertTrue(pushingNavVC.topViewController === pushingVC, "expected that nothing is presented")
    }

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

    // Given passcode is not set
    // and create passcode flow started
    // and it is not dismissable on swipe
    // when user swipes down
    // then the create passcode screen still shown

    // Given repeat passcode is shown
    // when user taps back
    // then goes back to create passcode

    // Given repeat passcode is shown
    // when user taps skip
    // then flow is closed

    // Given repeat passcode is shown
    // when user enters the correct passcode
    // then flow completed with success

    func startModalCreatePasscodeFlow() -> CreatePasscodeFlow {
        let flow = CreatePasscodeFlow(completion: { _ in })
        flow.modal(from: presenterVC)
        // wait for presentation animation to complete
        wait(timeout: animationDuration)
        return flow
    }

    func pushCreatePasscodeFlow() -> CreatePasscodeFlow {
        // present the hosting navigation stack
        presenterVC.present(pushingNavVC, animated: true)
        wait(timeout: animationDuration)

        // push flow on top of the stack
        let flow = CreatePasscodeFlow(completion: { _ in })
        pushingVC.push(flow: flow)
        wait(timeout: animationDuration)

        return flow
    }
}

// create passcode screen
    // enter 3 digits, erase one digit

// repeat passcode
    // enter 3 digits, erase
    // enter 6 digits, all different
    // enter 6 digits, 5 same, 1 different
