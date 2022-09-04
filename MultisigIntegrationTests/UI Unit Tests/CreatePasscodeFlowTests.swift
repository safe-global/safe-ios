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
    let animationDuration: TimeInterval = 1

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
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
    // when user enters a passcode
    // then "repeat passcode" screen shown
    func test_whenEntersPasscode_thenOpensRepeatPasscode() {
        // Given passcode is not set
        XCTAssertEqual(App.shared.auth.isPasscodeSetAndAvailable, false, "passcode must be not set")
        // and create passcode flow starts,
        let flow = startModalCreatePasscodeFlow()
        XCTAssertNotNil(flow) // to silence the 'unused' warning and retain the flow for duration of the test

        // when user enters a passcode
        guard let passcodeVC = topPresentedController() as? CreatePasscodeViewController else {
            XCTFail()
            return
        }
        passcodeVC.append(text: "123456")
        wait(timeout: animationDuration)

        // then "repeat passcode" screen shown
        let topScreen = topPresentedController()
        XCTAssertTrue(topScreen is RepeatPasscodeViewController, "not a repeat passcode screen")
    }

    // Given passcode is not set
    // and create passcode flow started
    // when user skips creating passcode
    // then the flow is closed
    func test_whenSkips_thenFlowClosed() {
        // Given passcode is not set
        XCTAssertEqual(App.shared.auth.isPasscodeSetAndAvailable, false, "passcode must be not set")
        // and create passcode flow starts,
        let flow = startModalCreatePasscodeFlow()
        XCTAssertNotNil(flow) // to silence the 'unused' warning and retain the flow for duration of the test

        // when user skips creating passcode
        guard let passcodeVC = topPresentedController() as? CreatePasscodeViewController else {
            XCTFail()
            return
        }
        passcodeVC.didTapButton(passcodeVC)
        wait(timeout: animationDuration)

        // then the flow is closed
        XCTAssertNil(presentedController, "expected that nothing is presented")
    }

    // Given passcode is not set
    // and create passcode flow started
    // when user swipes down
    // then the flow is closed
    func test_whenSwipesDown_thenFlowClosed() {
        // Given passcode is not set
        XCTAssertEqual(App.shared.auth.isPasscodeSetAndAvailable, false, "passcode must be not set")
        // and create passcode flow starts,
        let flow = startModalCreatePasscodeFlow()
        XCTAssertNotNil(flow) // to silence the 'unused' warning and retain the flow for duration of the test

        // when user swipes down
        guard let presentationController = presentedController?.presentationController,
              let presentationDelegate = presentationController.delegate else {
            XCTFail()
            return
        }
        presentationDelegate.presentationControllerDidDismiss?(presentationController)
        wait(timeout: animationDuration)

        // then the flow is closed
        XCTAssertNil(presentedController, "expected that nothing is presented")
    }

    // Given passcode is not set
    // and create passcode flow started
    // and it is not dismissable on swipe
    // when user swipes down
    // then the create passcode screen still shown
    func test_whenSwipesDownButNotDismissable_thenFlowNotClosed() {
        // Given passcode is not set
        XCTAssertEqual(App.shared.auth.isPasscodeSetAndAvailable, false, "passcode must be not set")
        // and create passcode flow starts,
        let flow = startModalCreatePasscodeFlow(dismissableOnSwipe: false)
        XCTAssertNotNil(flow) // to silence the 'unused' warning and retain the flow for duration of the test

        // when user swipes down
        guard let presentationController = presentedController?.presentationController,
              let presentationDelegate = presentationController.delegate else {
            XCTFail()
            return
        }
        presentationDelegate.presentationControllerDidDismiss?(presentationController)
        wait(timeout: animationDuration)

        if let vc = presentedController {
            XCTAssertTrue(vc.isModalInPresentation)
        }

        // then the screen is still shown
        XCTAssertNotNil(presentedController, "expected that controller is still on screen")
    }

    // Given repeat passcode is shown
    // when user taps back
    // then goes back to create passcode
    func test_whenBackFromRepeatPasscode_thenShowsCreatePasscode() {
        // Given repeat passcode is shown
        let flow = navigateToRepeatPasscodeScreen()
        XCTAssertNotNil(flow)

        // when user taps back
        (topPresentedController() as? RepeatPasscodeViewController)?.navigateBack()
        wait(timeout: animationDuration)

        // then goes back to create passcode
        XCTAssertTrue(topPresentedController() is CreatePasscodeViewController, "expected to find create passcode screen")
    }

    // Given repeat passcode is shown
    // when user taps skip
    // then flow is closed
    func test_whenSkipsRepeatPasscode_thenClosesFlow() {
        // Given repeat passcode is shown
        let flow = navigateToRepeatPasscodeScreen()
        XCTAssertNotNil(flow)

        // when user taps skip
        (topPresentedController() as? RepeatPasscodeViewController)?.didTapButton(self)
        wait(timeout: animationDuration)

        // then flow is closed
        XCTAssertNil(presentedController, "expected that nothing is presented")
    }

    // Given repeat passcode is shown
    // and device does not supports biometrics
    // when user enters the correct passcode
    // then flow completed with success
    func test_whenRepeatsPasscodeCorrectly_thenSuccessfullyCompletesFlow() {
        // Given repeat passcode is shown
        // and device does not supports biometrics
        App.shared.auth.test_override_isBiometrySupported = false

        var completionResult: Bool?
        let exp = expectation(description: "Flow completed")
        let flow = navigateToRepeatPasscodeScreen(passcode: "123456") { result in
            completionResult = result
            exp.fulfill()
        }
        XCTAssertNotNil(flow)

        // when user enters the correct passcode
        (topPresentedController() as? RepeatPasscodeViewController)?.append(text: "123456")
        wait(timeout: animationDuration)

        _ = XCTWaiter.wait(for: [exp], timeout: animationDuration)

        // then flow completed with success
        XCTAssertEqual(completionResult, true, "Flow not completed successfully")
    }

    // Given repeat passcode is shown
    // and device supports biometrics
    // when user enters the correct passcode
    // then biometry prompt is shown
    func test_whenRepeatsPasscodeCorrectlyAndBiometricsSupported_thenShowsBiometryPrompt() {
        // Given repeat passcode is shown
        // and device supports biometrics
        App.shared.auth.test_override_isBiometrySupported = true
        let flow = navigateToRepeatPasscodeScreen(passcode: "123456")
        XCTAssertNotNil(flow)

        // when user enters the correct passcode
        (topPresentedController() as? RepeatPasscodeViewController)?.append(text: "123456")
        wait(timeout: animationDuration)

        // then biometry prompt is shown
        XCTAssertTrue(topPresentedController().presentedViewController is UIAlertController)
    }

    // Given biometry prompt is shown
    // when cancels
    // then flow completed with success
    func test_whenBiometryCancelled_thenClosesWithSuccess() {
        // Given biometry prompt is shown
        App.shared.auth.test_override_isBiometrySupported = true
        var completionResult: Bool?
        let exp = expectation(description: "Flow completed")
        let flow = navigateToRepeatPasscodeScreen(passcode: "123456") { result in
            completionResult = result
            exp.fulfill()
        }
        XCTAssertNotNil(flow)
        (topPresentedController() as? RepeatPasscodeViewController)?.append(text: "123456")
        wait(timeout: animationDuration)

        // when cancels
        (topPresentedController().presentedViewController as? ActivateBiometryAlertController)?.cancel()
        
        _ = XCTWaiter.wait(for: [exp], timeout: animationDuration)

        // then flow completed with success
        XCTAssertEqual(completionResult, true, "Flow not completed successfully")
    }

    // TODO: re-write biometry testing using the Darwin notifications https://github.com/KaneCheshire/BiometricAutomationDemo

    func startModalCreatePasscodeFlow(dismissableOnSwipe: Bool = true, completion: @escaping (Bool) -> Void = { _ in }) -> CreatePasscodeFlow {
        let flow = CreatePasscodeFlow(completion: completion)
        flow.modal(from: presenterVC, dismissableOnSwipe: dismissableOnSwipe)
        // wait for presentation animation to complete
        wait(timeout: animationDuration)
        return flow
    }

    func navigateToRepeatPasscodeScreen(passcode: String = "123456", line: UInt = #line, completion: @escaping (Bool) -> Void = { _ in }) -> UIFlow {
        let flow = startModalCreatePasscodeFlow(completion: completion)

        (topPresentedController() as? CreatePasscodeViewController)?.append(text: passcode)
        wait(timeout: animationDuration)
        XCTAssertTrue(topPresentedController() is RepeatPasscodeViewController, "repeat vc not found", line: line)

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
