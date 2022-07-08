//
//  CreatePasscodeFlowTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 08.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class CreatePasscodeFlowTests: CoreDataTestCase {

    // Given passcode is not set,
    // when create passcode flow starts,
    // then it shows 'create passcode' screen
    func test_showsCreatePasscode() {
        continueAfterFailure = false

        // database is reset before running the test.

        // precondition: check that the passcode is not set
            // App.shared.auth.isPasscodeSetAndAvailable is false
        XCTAssertFalse(App.shared.auth.isPasscodeSetAndAvailable, "passcode must be not set")

        // start the 'create passcode flow'

            // create the flow
        let flow = CreatePasscodeFlow(completion: { _ in })

            // create new window with a root view controller (which is presenter)
        let presenterVC = UIViewController()

        let window = UIWindow()
        window.rootViewController = presenterVC
        window.makeKeyAndVisible()

        // Present the flow modally
            // this will present modal animated, so we need to wait
            // for some time for the screen to appear.
        flow.modal(from: presenterVC)

        // wait for presentation animation to complete
        _ = XCTWaiter.wait(for: [expectation(description: "wait")], timeout: 0.5)

        // check that the current screen is the 'create passcode screen'

            // get the presented navigation controller
        guard let navigationController = presenterVC.presentedViewController as? UINavigationController else {
            XCTFail("expected to find navigationController, but found \(presenterVC.presentedViewController as Any)")
            return
        }
            // get the screen on top of the navigation stack (the last pushed screen)
        guard let topScreen = navigationController.topViewController else {
            XCTFail("expected a topViewController but found nil")
            return
        }
            // check that that screen is 'create passcode view controller'
        XCTAssertTrue(topScreen is CreatePasscodeViewController, "not a create passcode screen")
    }
}
