//
//  UIIntegrationTestCase.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 15.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest

class UIIntegrationTestCase: CoreDataTestCase {
    var originalWindow: UIWindow?
    var testWindow: UIWindow!
    var presenterVC: UIViewController!
    var pushingNavVC: UINavigationController!
    var pushingVC: UIViewController!

    var presentedController: UIViewController? {
         presenterVC.presentedViewController
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        // NOTE: each test starts with an empty database
        installTestWindow()

        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        // dismiss the flow
        presenterVC?.dismiss(animated: false)
        // wait for dismissal animation to complete
        wait(timeout: 0.5)

        removeTestWindow()
    }

    // MARK: - Utilities

    /// Creates new window with a root view controller (which is presenter)
    func installTestWindow(_ line: UInt = #line) {
        presenterVC = UIViewController()
        presenterVC.view.backgroundColor = .flatOrange

        pushingVC = UIViewController()
        pushingVC.view.backgroundColor = UIColor(red: 118.0/255.0, green: 251.0/255.0, blue: 155.0/255.0, alpha: 1)
        pushingNavVC = UINavigationController(rootViewController: pushingVC)


        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            XCTFail("Can't find scene to present window on it", line: line)
            return
        }

        originalWindow = scene.windows.first(where: { $0.isKeyWindow })

        testWindow = UIWindow(windowScene: scene)
        testWindow.frame = UIScreen.main.bounds
        testWindow.rootViewController = presenterVC
        testWindow.makeKeyAndVisible()
    }

    /// Removes test window and restore the one that was there before
    func removeTestWindow() {
        originalWindow?.makeKeyAndVisible()
        testWindow.removeFromSuperview()
        testWindow.windowScene = nil
    }

    /// Returns a view controller at the top of navigation stack from the presented navigation controller
    func topPresentedController(_ line: UInt = #line) -> UIViewController! {
        // get the presented navigation controller
        guard let navigationController = presentedController as? UINavigationController else {
            XCTFail("expected to find navigationController, but found \(presenterVC.presentedViewController as Any)", line: line)
            return nil
        }
        // get the screen on top of the navigation stack (the last pushed screen)
        guard let topScreen = navigationController.topViewController else {
            XCTFail("expected a topViewController but found nil", line: line)
            return nil
        }
        return topScreen
    }

    /// Waits for the timeout in seconds
    func wait(timeout: TimeInterval) {
        _ = XCTWaiter.wait(for: [expectation(description: "wait")], timeout: timeout)
    }

}
