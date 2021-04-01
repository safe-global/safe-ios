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
    var window: WindowWithViewOnTop?
    var snackbarViewController = SnackbarViewController(nibName: nil, bundle: nil)

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        App.shared.tokenRegistry.load()

        let darkNavBar = UINavigationBar.appearance(for: .init(userInterfaceStyle: .dark))
        darkNavBar.barTintColor = .quaternaryBackground
        darkNavBar.isTranslucent = false

        let lightNavBar = UINavigationBar.appearance(for: .init(userInterfaceStyle: .light))
        lightNavBar.barTintColor = nil
        lightNavBar.isTranslucent = true

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = WindowWithViewOnTop(windowScene: windowScene)
            self.window = window
            window.rootViewController = ViewControllerFactory.rootViewController()

            SnackbarViewController.instance = snackbarViewController
            snackbarViewController.view.frame = window.bounds
            snackbarViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            window.addSubviewAlwaysOnTop(snackbarViewController.view)

            window.tintColor = .button
            window.makeKeyAndVisible()
            App.shared.theme.setUp()
        }

        App.shared.notificationHandler.appStarted()

        if connectionOptions.notificationResponse == nil {
            App.shared.appReview.pullAppReviewTrigger()
        }

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

        try? WalletConnectController.shared.connect(url: wcURL)
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
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        App.shared.clientGatewayHostObserver.stopObserving()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        App.shared.notificationHandler.appEnteredForeground()
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
            print("url: \(context.url.absoluteURL)")
            print("scheme: \(context.url.scheme)")
            print("host: \(context.url.host)")
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

        try? WalletConnectController.shared.connect(url: wcURL)
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
