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
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if App.configuration.toggles.useUIKit {
            scene_uikit(scene, willConnectTo: session, options: connectionOptions)
        } else {
            scene_swiftUI(scene, willConnectTo: session, options: connectionOptions)
        }
    }

    func scene_uikit(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        App.shared.tokenRegistry.load()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = rootViewController()
            self.window = window
            window.tintColor = .gnoHold
            window.makeKeyAndVisible()
        }

        App.shared.notificationHandler.appStarted()
    }

    func rootViewController() -> UIViewController {
        let tabBarVC = UITabBarController()
        let balancesTabVC = balancesTabViewController()
        let settingsTabVC = settingsTabViewController()
        tabBarVC.viewControllers = [balancesTabVC, settingsTabVC]
        tabBarVC.tabBar.barTintColor = .gnoSnowwhite
        return tabBarVC
    }

    private func balancesTabViewController() -> UIViewController {
        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-coins"), title: "Coins"),
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-collectibles"), title: "Collectibles")
        ]
        segmentVC.viewControllers = [
            BalancesViewController(),
            CollectiblesViewController()
        ]
        segmentVC.selectedIndex = 0

        let noSafesVC = NoSafesViewController()
        noSafesVC.hasSafeViewController = segmentVC
        noSafesVC.noSafeViewController = LoadSafeViewController()

        let tabRoot = HeaderViewController(rootViewController: noSafesVC)
        return tabViewController(root: tabRoot, title: "Assets", image: #imageLiteral(resourceName: "tab-icon-balances.pdf"), tag: 0)
    }

    private func settingsTabViewController() -> UIViewController {
        let noSafesVC = NoSafesViewController()
        noSafesVC.hasSafeViewController = SafeSettingsViewController()
        noSafesVC.noSafeViewController = LoadSafeViewController()

        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-safe-settings"), title: "Safe Settings"),
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-app-settings"), title: "App Settings")
        ]
        segmentVC.viewControllers = [
            noSafesVC,
            AppSettingsViewController()
        ]
        segmentVC.selectedIndex = 0

        let tabRoot = HeaderViewController(rootViewController: segmentVC)
        return tabViewController(root: tabRoot, title: "Settings", image: #imageLiteral(resourceName: "tab-icon-settings"), tag: 1)
    }

    func tabViewController(root: UIViewController, title: String, image: UIImage, tag: Int) -> UIViewController {
        let nav = UINavigationController(rootViewController: root)
        let tabItem = UITabBarItem(title: title, image: image, tag: tag)
        nav.tabBarItem = tabItem
        return nav
    }

    func scene_swiftUI(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Get the managed object context from the shared persistent container.
        let context = App.shared.coreDataStack.persistentContainer.viewContext
        // Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
        // Add `@Environment(\.managedObjectContext)` in the views that will need the context.
        let contentView = ContentView()
            .environment(\.managedObjectContext, context)
            .environmentObject(AppViewModel.shared.coins)
            .environmentObject(AppViewModel.shared.collectibles)
            .environmentObject(AppViewModel.shared.transactions)
            .environmentObject(AppViewModel.shared.safeSettings)

        App.shared.tokenRegistry.load()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }

        App.shared.notificationHandler.appStarted()
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
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
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
    }
}
