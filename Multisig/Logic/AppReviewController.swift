//
//  AppReviewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/3/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import StoreKit
import UIKit

/// Encapsulates the app review triggering logic.
class AppReviewController: NSObject {

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didFinishLaunching(_:)),
                                               name: UIApplication.didFinishLaunchingNotification,
                                               object: nil)
    }

    /// Trigger in-app review dialog on 3rd app start (for the first time)
    ///      - don't count app starts triggered by a push notification
    ///
    /// After the dialog is triggered for the first time, use the same logic
    /// as before for subsequent in-app reviews
    /// (to handle cases when the user canceled the flow).
    ///
    /// This means count to 3 again, not including starts from push notifications.
    @objc func didFinishLaunching(_ notification: Notification) {
        // skip if launched from a push notification
        guard notification.userInfo?[UIApplication.LaunchOptionsKey.remoteNotification.rawValue] == nil else { return }

        // skip if not accepted the terms
        guard AppSettings.termsAccepted else { return }

        // will be 0 if never counted yet
        AppSettings.appReviewEventCount += 1

        if AppSettings.appReviewEventCount >= 3 {
            SKStoreReviewController.requestReview()
            AppSettings.appReviewEventCount = 0
        }
    }

}
