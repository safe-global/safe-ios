//
//  TestingAppDelegate.swift
//  MultisigTests
//
//  Created by Vitaly Katz on 24.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

@objc(TestingAppDelegate)
class TestingAppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            print("<< Launching with testing app delegate")
            return true
    }
}
