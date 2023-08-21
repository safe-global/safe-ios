//
//  SceneDelegate.swift
//  Multisig
//
//  Created by Dmitry Bespalov. on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//
import UIKit
import SwiftUI
import CustomAuth

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
#if DEBUG
        guard UIApplication.shared.delegate is AppDelegate else {
            // assume we're in a testing mode, so exit any further configuration
            return
        }
#endif

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

        NotificationCenter.default.addObserver(self, selector: #selector(handlePasscodeRequired),
                                               name: .passcodeRequired,
                                               object: nil)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
#if DEBUG
        guard UIApplication.shared.delegate is AppDelegate else {
            // assume we're in a testing mode, so exit any further configuration
            return
        }
#endif

        App.shared.notificationHandler.appEnteredForeground()

        if scene.activationState == .unattached && updateAppWindow?.rootViewController != nil {
            showWindow(updateAppWindow)
        } else {
            onAppUpdateCompletion()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
#if DEBUG
        guard UIApplication.shared.delegate is AppDelegate else {
            // assume we're in a testing mode, so exit any further configuration
            return
        }
#endif

        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        App.shared.clientGatewayHostObserver.startObserving()

        PendingTransactionMonitor.scheduleMonitoring()
        RelayedTransactionMonitor.scheduleMonitoring()
        SafeCreationMonitor.scheduleMonitoring()
        WebConnectionExpirationMonitor.scheduleMonitoring()

        privacyShieldWindow?.isHidden = true

        if let viewController = updateAppWindow?.rootViewController as? UpdateAppViewController, viewController.style == .required {
            showWindow(updateAppWindow)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
#if DEBUG
        guard UIApplication.shared.delegate is AppDelegate else {
            // assume we're in a testing mode, so exit any further configuration
            return
        }
#endif

        App.shared.clientGatewayHostObserver.stopObserving()

        PendingTransactionMonitor.stopMonitoring()
        WebConnectionExpirationMonitor.stopMonitoring()

        if presentedWindow === tabBarWindow {
            privacyShieldWindow?.isHidden = false
        }
        IntercomConfig.hide()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
#if DEBUG
        guard UIApplication.shared.delegate is AppDelegate else {
            // assume we're in a testing mode, so exit any further configuration
            return
        }
#endif
        // Save changes in the application's managed object context when the application transitions to the background.
        App.shared.coreDataStack.saveContext()

        App.shared.securityCenter.lockDataStore()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
#if DEBUG
        guard UIApplication.shared.delegate is AppDelegate else {
            // assume we're in a testing mode, so exit any further configuration
            return
        }
#endif

        handleUserActivity(userActivity)
    }

    // Handles opening of a universal link.
    //
    // Supported link types:
    // - WalletConnect links from dapps to connect to the safe
    //   - 'connect' link to establish new connection
    //   - 'open' link to move the app to foreground so that it is able to process WalletConnect request or response.
    // - Request To Add Owner 
    //   - <web app url>/addOwner?safe=<safe_address>&address=<owner_address>
    // - Web3auth
    //   - handled by CustomAuth.handle()
    private func handleUserActivity(_ userActivity: NSUserActivity) {
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return
        }

        // handle wallet connect
        if let wcURL = components.queryItems?.first?.value,
           (try? Safe.getSelected()) != nil {
            if WalletConnectManager.shared.canConnect(url: wcURL) {
                WalletConnectManager.shared.pairClient(url: wcURL, trackingEvent: .dappConnectedWithUniversalLink)
            } else if WalletConnectSafesServerController.shared.canConnect(url: wcURL) {
                try? WalletConnectSafesServerController.shared.connect(url: wcURL)
                WalletConnectSafesServerController.shared.dappConnectedTrackingEvent = .dappConnectedWithUniversalLink
                return
            }
        }

        // handle request to add owner
        if AddOwnerRequestValidator.isValid(url: incomingURL),
           let params = AddOwnerRequestValidator.parameters(from: incomingURL) {
            CompositeNavigationRouter.shared.navigate(to: .requestToAddOwner(params))
            return
        }

        if let navigationRoute = CompositeNavigationRouter.shared.routeFrom(from: incomingURL) {
            CompositeNavigationRouter.shared.navigate(to: navigationRoute)
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

    func makeFaceIDUnlockWindow() -> UIWindow {
        let faceIDUnlockWindow = makeWindow(scene: scene!)
        faceIDUnlockWindow.rootViewController = ViewControllerFactory.faceIDUnlockViewController { [unowned self] in
            onFaceIDCheckCompletion()
        }
        return faceIDUnlockWindow
    }


    func makeEnterPasscodeWindow(showsCloseButton: Bool = false,
                                 completion: ((EnterPasscodeViewController.Result) -> Void)? = nil) -> UIWindow {
        let enterPasscodeWindow = makeWindow(scene: scene!)

        let vc = ViewControllerFactory.enterPasscodeViewController (showsCloseButton: showsCloseButton) { [unowned self] result in
            if case let EnterPasscodeViewController.Result.success(passcode) = result {
                onEnterPasscodeCompletion(userPassword: passcode)
            } else {
                showMainContentWindow()
            }

            completion?(result)
        }

        enterPasscodeWindow.rootViewController = vc
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
            // TODO: Enable when implemented new security center
        } else if shouldShowPasscode && !AppConfiguration.FeatureToggles.securityCenter {
            showWindow(makeEnterPasscodeWindow())
        } else if App.shared.securityCenter.shouldShowFaceID() {
            showWindow(makeFaceIDUnlockWindow())
        } else if App.shared.securityCenter.shouldShowPasscode() {
            showWindow(makeEnterPasscodeWindow())
        } else if !AppSettings.onboardingCompleted {
            showOnboardingWindow()
        } else {
            showMainContentWindow()
        }
    }

    func showMainContentWindow() {
        showWindow(tabBarWindow)
        IntercomConfig.appDidShowMainContent()
    }

    func onTermsCompletion() {
        showWindow(makeOnboardingWindow())
    }

    func onOnboardingCompletion() {
        showMainContentWindow()
    }

    // userPassword can be nil if passcode is disabled
    func onEnterPasscodeCompletion(userPassword: String? = nil) {
        do {
            if AppConfiguration.FeatureToggles.securityCenter {
                try App.shared.securityCenter.unlockDataStore(userPassword: userPassword)
            }
            showMainContentWindow()
        } catch {
            LogService.shared.error("Failed to unlock", error: error)
        }
    }

    func onFaceIDCheckCompletion() {
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

    @objc private func handlePasscodeRequired(_ notification: Notification) {
        guard let task = notification.userInfo?["accessTask"] as? (_ password: String?) -> Void else {
            return
        }

        DispatchQueue.main.async { [unowned self] in
            showWindow(makeEnterPasscodeWindow(showsCloseButton: true) { result in
                switch result {
                case .success(let password):
                    task(password)
                case .close:
                    return
                }
            })
        }
    }
}

extension SceneDelegate: NavigationRouter {
    func routeFrom(from url: URL) -> NavigationRoute? {
        nil
    }
    
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
