//
//  AppReviewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/3/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import StoreKit

/// Encapsulates the app review triggering logic.
class AppReviewController {

    /// Call this on the app start except when starting from notification.
    ///
    /// Trigger in-app review dialog on 3rd app start (for the first time)
    ///      - don't count app starts triggered by a push notification
    ///
    /// After the dialog is triggered for the first time, use the same logic
    /// as before for subsequent in-app reviews
    /// (to handle cases when the user canceled the flow).
    ///
    /// This means count to 3 again, not including starts from push notifications.
    func pullAppReviewTrigger() {
        guard AppSettings.termsAccepted else { return }

        // will be 0 if never counted yet
        AppSettings.appReviewEventCount += 1

        if AppSettings.appReviewEventCount >= 3 {
            SKStoreReviewController.requestReview()
            AppSettings.appReviewEventCount = 0
        }
    }

}
