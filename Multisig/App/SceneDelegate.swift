//
//  SceneDelegate.swift
//  Multisig
//
//  Created by Dmitry Bespalov. on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// States of the window state machine governing when and which windows to show
    ///
    /// Allowed transitions:
    ///
    /// - from `none`
    ///     - to `main` - on startup, if no passcode needed
    ///     - to `privacy` - on startup, if passcode is needed
    /// - from `privacy`
    ///     - to `privacyPasscode` - on enter foreground, if passcode is needed
    ///     - to `main` - on become active
    /// - from `privacyPasscode`
    ///     - to `main` - when passcode challenge is closed
    /// - from `main`
    ///     - to `privacy` - on resign active
    ///
    private enum WindowState {
        /// None of the windows is shown
        case none
        /// Main window is shown
        case main
        /// Privacy window is shown
        case privacy
        /// Privacy window is shown and the passcode prompt is presented
        case privacyPasscode
    }

    var snackbarViewController = SnackbarViewController(nibName: nil, bundle: nil)
    private var delayedMainPresentedViewController: UIViewController?

    private var mainWindow: WindowWithViewOnTop?
    private var privacyProtectionWindow: WindowWithViewOnTop?

    private var windowState: WindowState = .none

    private var shouldShowPasscode: Bool {
        App.shared.auth.isPasscodeSet && AppSettings.passcodeOptions.contains(.useForLogin)
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        App.shared.tokenRegistry.load()

        let darkNavBar = UINavigationBar.appearance(for: .init(userInterfaceStyle: .dark))
        darkNavBar.barTintColor = .quaternaryBackground
        darkNavBar.isTranslucent = false

        let lightNavBar = UINavigationBar.appearance(for: .init(userInterfaceStyle: .light))
        lightNavBar.barTintColor = nil
        lightNavBar.isTranslucent = true

        if let scene = scene as? UIWindowScene {
            mainWindow = makeMainWindow(scene: scene)
            privacyProtectionWindow = makePrivacyWindow(scene: scene)
            showStartingWindow()

            App.shared.theme.setUp()
        }

        App.shared.notificationHandler.appStarted()
        App.shared.appReview.startedFromNotification = connectionOptions.notificationResponse != nil

        // Get URL components from the incoming user activity.
        guard let userActivity = connectionOptions.userActivities.first,
              userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return
        }

        // Check if URL is a potential WalletConnect session
        guard let params = components.queryItems,
              !params.isEmpty,
              let wcURL = params[0].value else {
            return
        }

        try? WalletConnectServerController.shared.connect(url: wcURL)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        SynchronizationService.shared.startSyncLoop()
        App.shared.clientGatewayHostObserver.startObserving()

        if windowState == .privacy {
            showMainWindow()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        App.shared.clientGatewayHostObserver.stopObserving()

        if windowState == .main {
            showPrivacyWindow()
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        // The `sceneDidBecomeActive()` is called after this method.

        App.shared.notificationHandler.appEnteredForeground()

        // Check if we have copied WalletConnect url in the Pasteboard and handle it
        if let potentialWCUrl = Pasteboard.string, potentialWCUrl.hasPrefix("wc:") {
            do {
                App.shared.snackbar.show(message: "Creating WalletConnect session. This might take some time.")
                try WalletConnectServerController.shared.connect(url: potentialWCUrl)
                // if setting nil it will crash
                Pasteboard.string = ""
            } catch {
                App.shared.snackbar.show(message: "Failed to create a WalletConnect session.")
            }
        }
        
        if windowState == .privacy {
            showPasscodePrompt()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        App.shared.coreDataStack.saveContext()
        SynchronizationService.shared.stopSyncLoop()
    }

    #warning("TODO: finish deep links support for WalletConnect")
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            print("[WALLETCONNECT]")
            print("url: \(context.url.absoluteURL)")
            print("scheme: \(String(describing: context.url.scheme))")
            print("host: \(String(describing: context.url.host))")
            print("path: \(context.url.path)")
            print("components: \(context.url.pathComponents)")
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return
        }

        // Check if URL is a potential WalletConnect session
        guard let params = components.queryItems,
              !params.isEmpty,
              let wcURL = params[0].value else {
            return
        }

        try? WalletConnectServerController.shared.connect(url: wcURL)
    }

    // MARK: - Window Management

    func presentForMain(_ controller: UIViewController) {
        if windowState == .main {
            mainWindow?.rootViewController?.present(controller, animated: true)
        } else {
            delayedMainPresentedViewController = controller
        }
    }

    private func showStartingWindow() {
        if shouldShowPasscode {
            showPrivacyWindow()
        } else {
            showMainWindow()
        }
    }

    private func showMainWindow() {
        if snackbarViewController.view.window != mainWindow, let window = mainWindow {
            window.addSubviewAlwaysOnTop(snackbarViewController.view)
        }
        mainWindow?.makeKeyAndVisible()
        if delayedMainPresentedViewController != nil {
            mainWindow?.rootViewController?.present(delayedMainPresentedViewController!, animated: true)
            delayedMainPresentedViewController = nil
        }
        windowState = .main
    }

    private func showPrivacyWindow() {
        if snackbarViewController.view.window != privacyProtectionWindow, let window = privacyProtectionWindow {
            window.addSubviewAlwaysOnTop(snackbarViewController.view)
        }
        privacyProtectionWindow?.makeKeyAndVisible()
        windowState = .privacy
    }

    private func makeMainWindow(scene: UIWindowScene) -> WindowWithViewOnTop {
        let window = WindowWithViewOnTop(windowScene: scene)
        window.rootViewController = ViewControllerFactory.rootViewController()

        SnackbarViewController.instance = snackbarViewController
        snackbarViewController.view.frame = window.bounds
        snackbarViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubviewAlwaysOnTop(snackbarViewController.view)

        window.tintColor = .button
        return window
    }

    private func makePrivacyWindow(scene: UIWindowScene) -> WindowWithViewOnTop {
        let window = WindowWithViewOnTop(windowScene: scene)
        window.rootViewController = PrivacyProtectionScreenViewController()
        return window
    }

    // MARK: - Passcode

    private func showPasscodePrompt() {
        guard shouldShowPasscode else { return }

        let vc = EnterPasscodeViewController()
        vc.showsCloseButton = false

        // because close button is hidden, this will complete only
        // if passcode is correct or if the data is deleted.
        // in both cases, we want to show the main window.
        vc.completion = { [weak self] _ in
            self?.privacyProtectionWindow?.rootViewController?.dismiss(animated: true) { [weak self] in
                self?.showMainWindow()
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen

        privacyProtectionWindow?.rootViewController?.present(nav, animated: true, completion: nil)

        windowState = .privacyPasscode
    }
}

// Window that can keep some view always on top of other views
class WindowWithViewOnTop: UIWindow {

    private weak var keepInFront: UIView?

    func addSubviewAlwaysOnTop(_ view: UIView) {
        keepInFront = view
        addSubview(view)
    }

    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        if let v = keepInFront {
            bringSubviewToFront(v)
        }
    }
}
