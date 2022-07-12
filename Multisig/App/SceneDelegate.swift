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

    var snackbarViewController = SnackbarViewController(nibName: nil, bundle: nil)

    var updateAppWindow: UIWindow?
    var tabBarWindow: UIWindow?
    var privacyShieldWindow: UIWindow?

    // the window to present
    var presentedWindow: UIWindow?

    private var shouldShowPasscode: Bool {
        App.shared.auth.isPasscodeSetAndAvailable && AppSettings.passcodeOptions.contains(.useForLogin)
    }

    private var startedFromNotification: Bool {
        get { App.shared.appReview.startedFromNotification }
        set { App.shared.appReview.startedFromNotification = newValue }
    }

    weak var scene: UIWindowScene?

    // MARK: - Scene Life Cycle
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let darkNavBar = UINavigationBar.appearance(for: .init(userInterfaceStyle: .dark))
        darkNavBar.barTintColor = .backgroundQuaternary
        darkNavBar.isTranslucent = false

        let lightNavBar = UINavigationBar.appearance(for: .init(userInterfaceStyle: .light))
        lightNavBar.barTintColor = nil
        lightNavBar.isTranslucent = true

        App.shared.notificationHandler.appStarted()
        startedFromNotification = connectionOptions.notificationResponse != nil

        if let scene = scene as? UIWindowScene {
            self.scene = scene
            makeWindows(scene: scene)
        }

        App.shared.appReview.startedFromNotification = connectionOptions.notificationResponse != nil

        if let userActivity = connectionOptions.userActivities.first {
            handleUserActivity(userActivity)
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        App.shared.notificationHandler.appEnteredForeground()

        if scene.activationState == .unattached && updateAppWindow?.rootViewController != nil {
            showWindow(updateAppWindow)
        } else {
            onAppUpdateCompletion()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        App.shared.clientGatewayHostObserver.startObserving()

        PendingTransactionMonitor.scheduleMonitoring()
        SafeCreationMonitor.scheduleMonitoring()
        WebConnectionExpirationMonitor.scheduleMonitoring()

        privacyShieldWindow?.isHidden = true

        if let viewController = updateAppWindow?.rootViewController as? UpdateAppViewController, viewController.style == .required {
            showWindow(updateAppWindow)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        App.shared.clientGatewayHostObserver.stopObserving()

        PendingTransactionMonitor.stopMonitoring()
        WebConnectionExpirationMonitor.stopMonitoring()

        if presentedWindow === tabBarWindow {
            privacyShieldWindow?.isHidden = false
        }
        App.shared.intercomConfig.hide()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save changes in the application's managed object context when the application transitions to the background.
        App.shared.coreDataStack.saveContext()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUserActivity(userActivity)
    }

    // Handles opening of a universal link.
    //
    // Supported link types:
    // - WalletConnect links from dapps to connect to the safe
    //   - 'connect' link to establish new connection
    //   - 'open' link to move the app to foreground so that it is able to process WalletConnect request or response.
    // - Request To Add Owner
    //   - https://gnosis-safe.io/app/<network:safe_address>/addOwner?address=<owner_address>
    private func handleUserActivity(_ userActivity: NSUserActivity) {
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return
        }

        // handle wallet connect
        if let wcURL = components.queryItems?.first?.value,
           WalletConnectSafesServerController.shared.canConnect(url: wcURL),
           (try? Safe.getSelected()) != nil {
            try? WalletConnectSafesServerController.shared.connect(url: wcURL)
            WalletConnectSafesServerController.shared.dappConnectedTrackingEvent = .dappConnectedWithUniversalLink
            return
        }

        // handle request to add owner
        if AddOwnerRequestValidator.isValid(url: incomingURL),
           let params = AddOwnerRequestValidator.parameters(from: incomingURL) {
            DefaultNavigationRouter.shared.navigate(to: .requestToAddOwner(params))
            return
        }

        if let navigationRoute = DefaultNavigationRouter.shared.routeFrom(from: incomingURL) {
            DefaultNavigationRouter.shared.navigate(to: navigationRoute)
        }
    }

    // MARK: - Window Management

    func present(_ controller: UIViewController) {
        tabBarWindow?.rootViewController?.present(controller, animated: true)
    }

    private func makeWindow(scene: UIWindowScene) -> UIWindow {
        let window = WindowWithViewOnTop(windowScene: scene)
        window.tintColor = .primary
        return window
    }

    private func showWindow(_ window: UIWindow?) {
        guard let window = window else { return }

        if let customWindow = window as? WindowWithViewOnTop {
            snackbarViewController.view.frame = customWindow.bounds
            customWindow.addSubviewAlwaysOnTop(snackbarViewController.view)
        }

        window.makeKeyAndVisible()
        App.shared.theme.setUp()

        presentedWindow = window
    }

    private func makeWindows(scene: UIWindowScene) {
        // snack bar
        SnackbarViewController.instance = snackbarViewController
        snackbarViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        updateAppWindow = makeUpdateAppWindow()
        tabBarWindow = makeTabBarWindow()
        privacyShieldWindow = makePrivacyShieldWindow()
    }

    func makeUpdateAppWindow() -> UIWindow {
        let updateAppWindow = makeWindow(scene: scene!)
        if let controller = App.shared.updateController.makeUpdateAppViewController() {
            updateAppWindow.rootViewController = controller

            controller.completion = { [unowned self] in
                onAppUpdateCompletion()
            }
        }
        return updateAppWindow
    }

    func makeTabBarWindow() -> UIWindow {
        let tabBarWindow = makeWindow(scene: scene!)
        tabBarWindow.rootViewController = ViewControllerFactory.tabBarViewController(completion: { [unowned self] tabBar in
            onTabBarAppearance(of: tabBar)
        })
        return tabBarWindow
    }

    func makeEnterPasscodeWindow() -> UIWindow {
        let enterPasscodeWindow = makeWindow(scene: scene!)
        enterPasscodeWindow.rootViewController = ViewControllerFactory.enterPasscodeViewController { [unowned self] in
            onEnterPasscodeCompletion()
        }
        return enterPasscodeWindow
    }

    func makePrivacyShieldWindow() -> UIWindow {
        let privacyShieldWindow = makeWindow(scene: scene!)
        privacyShieldWindow.rootViewController = PrivacyProtectionScreenViewController()
        return privacyShieldWindow
    }

    func makeTermsWindow() -> UIWindow {
        let termsWindow = makeWindow(scene: scene!)
        termsWindow.rootViewController = ViewControllerFactory.termsViewController { [unowned self] in
            onTermsCompletion()
        }
        return termsWindow
    }

    func showOnboardingWindow() {
        if let presentedWindow = presentedWindow,
           let root = presentedWindow.rootViewController,
           root is OnboardingViewController {
            return
        }

        showWindow(makeOnboardingWindow())
    }

    func makeOnboardingWindow() -> UIWindow {
        AppSettings.onboardingCompleted = false

        let onboardingWindow = makeWindow(scene: scene!)
        onboardingWindow.rootViewController = OnboardingViewController(completion: { [unowned self] in
            AppSettings.onboardingCompleted = true
            onOnboardingCompletion()
        })

        return onboardingWindow
    }

    func onAppUpdateCompletion() {
        if !AppSettings.termsAccepted {
            showWindow(makeTermsWindow())
        } else if shouldShowPasscode {
            showWindow(makeEnterPasscodeWindow())
        } else if !AppSettings.onboardingCompleted {
            showOnboardingWindow()
        } else {
            showMainContentWindow()
        }
    }
    
    func showMainContentWindow() {
        showWindow(tabBarWindow)
        App.shared.intercomConfig.appDidShowMainContent()
    }

    func onTermsCompletion() {
        showWindow(makeOnboardingWindow())
    }

    func onOnboardingCompletion() {
        showMainContentWindow()
    }

    func onEnterPasscodeCompletion() {
        showMainContentWindow()
    }

    func onTabBarAppearance(of tabBar: MainTabBarViewController) {
        if startedFromNotification, let safeTxHash = App.shared.notificationHandler.transactionDetailsPayload {
            // present transaction details
            App.shared.notificationHandler.transactionDetailsPayload = nil
            let vc = ViewControllerFactory.transactionDetailsViewController(safeTxHash: safeTxHash)
            tabBar.present(vc, animated: true, completion: nil)

        } else if App.shared.notificationHandler.needsToRequestNotificationPermission {
            App.shared.notificationHandler.requestUserPermissionAndRegister()

        } else {
            App.shared.appReview.pullAppReviewTrigger()
        }
    }
}

extension SceneDelegate: NavigationRouter {
    func canNavigate(to route: NavigationRoute) -> Bool {
        guard let tabWindow = tabBarWindow, let tabBarVC = tabWindow.rootViewController as? MainTabBarViewController else { return false }
        return tabBarVC.canNavigate(to: route)
    }

    func navigate(to route: NavigationRoute) {
        guard let tabWindow = tabBarWindow, let tabBarVC = tabWindow.rootViewController as? MainTabBarViewController else { return }
        tabBarVC.navigate(to: route)
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
