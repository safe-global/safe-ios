//
//  AppDelegate.swift
//  Multisig
//
//  Created by Dmitry Bespalov. on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        configureGloabalAppearance()
        return true
    }

    private func configureGloabalAppearance() {
        // we don't set the image for the navbar (pdf) as it crashes the app;
        // we don't set the `translucent` property of navbar to false because
        // it crashes the app (SwiftUI).
        // but shadow works.
        UINavigationBar.appearance().shadowImage = UIImage(named: "shadow")
        UINavigationBar.appearance().tintColor = UIColor(named: "hold")

        // non-zero height view adds the bottom space to the table views
        UITableView.appearance().tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 100))
        // makes separators to take full width of the screen
        // (default is with offset)
        UITableView.appearance().separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        // changes SwiftUI's List background color - List.background() does
        // not work.
        UITableView.appearance().backgroundColor = UIColor(named: "white")
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
