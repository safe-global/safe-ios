//
//  AppDelegate.swift
//  Multisig
//
//  Created by Dmitry Bespalov. on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import Firebase

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        App.shared.firebaseConfig.setUp()
        IntercomConfig.setUp()

        UIApplication.shared.registerForRemoteNotifications()

        #if DEBUG
        Tracker.append(handler: ConsoleTracker())
        #endif
        Tracker.append(handler: FirebaseTrackingHandler())

        Tracker.setTrackingEnabled(AppSettings.trackingEnabled)

        AppSettings.saveCurrentRunVersionNumber()

        ChainManager.migrateOldSafes()
        ChainManager.updateChainsInfo()

        //TODO: adjust cleanUpKeys for security v2
        if !AppConfiguration.FeatureToggles.securityCenter {
            OwnerKeyController.cleanUpKeys()
            // after security v2 migration this line won't be needed
            OwnerKeyController.migrateLegacySigningKey()
        }

        App.shared.auth.migrateFromPasscodeV1()

        // The requirement is to set num_safes property to "0" when there are no Safes
        Tracker.setNumSafesUserProperty(Safe.countExcludingDemo)
        
        Tracker.setNumKeys(KeyInfo.count(.deviceGenerated), type: .deviceGenerated)
        Tracker.setNumKeys(KeyInfo.count(.deviceImported), type: .deviceImported)
        Tracker.setNumKeys(KeyInfo.count(.walletConnect), type: .walletConnect)
        Tracker.setNumKeys(KeyInfo.count(.ledgerNanoX), type: .ledgerNanoX)
        Tracker.setNumKeys(KeyInfo.count(.keystone), type: .keystone)
        Tracker.setNumKeys(KeyInfo.count(.web3AuthApple), type: .web3AuthApple)
        Tracker.setNumKeys(KeyInfo.count(.web3AuthGoogle), type: .web3AuthGoogle)
        Tracker.setPasscodeIsSet(to: App.shared.auth.isPasscodeSetAndAvailable)        
        Tracker.setWalletConnectForDappsEnabled(true)

        Safe.updateCachedNames()
        AddressBookEntry.updateCachedNames()

        App.shared.notificationHandler.setUpMessaging(delegate: self)
        // Reconnect all WalletConnect sessions
        WalletConnectSafesServerController.shared.reconnectAllSessions()

        WCAppRegistryMigration.shared.run()

        SecurityCenter.setUp()
        WalletConnectManager.shared.config()
        App.shared.ramper.config()
        return true
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

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        LogService.shared.error("PUSH: Failed to register to remote notifications \(error)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        LogService.shared.debug("PUSH: Received APNS token: \(deviceToken.toHexStringWithPrefix())")
        Messaging.messaging().apnsToken = deviceToken
        IntercomConfig.setDeviceToken(deviceToken) { error in
            // this will fail before a Safe was added
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        LogService.shared.debug("PUSH: didReceiveRemoteNotification with userInfo: \(userInfo)")
        Messaging.messaging().appDidReceiveMessage(userInfo)

        if IntercomConfig.isIntercomPushNotification(userInfo) {
            LogService.shared.debug("PUSH: didReceiveRemoteNotification Intercom push notification with userInfo: \(userInfo)")
            IntercomConfig.pushNotificationUserInfo = userInfo
        }

        completionHandler(.noData)
    }

}
