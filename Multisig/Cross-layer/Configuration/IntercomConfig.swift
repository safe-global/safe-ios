//
// Created by Dirk Jäckel on 23.11.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import Intercom

class IntercomConfig {

    var pushNotificationUserInfo: [AnyHashable : Any]?

    func setUp() {
        Intercom.setApiKey(App.configuration.services.intercomApiKey, forAppId: App.configuration.services.intercomAppId)

        #if DEBUG
        Intercom.enableLogging()
        #endif
        Intercom.loginUnidentifiedUser { result in
            switch result {
            case .success:
                LogService.shared.debug("Anonymous login to Intercm succeeded")
            case .failure(let error):
                App.shared.snackbar.show(message: "Anonymous login to Intercom failed: \(error)")
            }
        }
        disableChatOverlay()
    }

    func disableChatOverlay() {
        Intercom.setInAppMessagesVisible(false)
    }

    func startChat() {
        Intercom.present()
    }

    func hide() {
        Intercom.hide()
    }

    func appDidShowMainContent() {
        // adding delay hack to handle the case when this shows right after app start -  in that case we would see the
        // black window background behind the intercom window. We give the app time to initialize.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) { [weak self] in
            guard let self = self, let userInfo = self.pushNotificationUserInfo else {
                return
            }
            self.pushNotificationUserInfo = nil
            Intercom.handlePushNotification(userInfo)
            self.startChat()
        }
    }

    func unreadConversationCount() -> UInt {
        Intercom.unreadConversationCount()
    }
    
    func isIntercomPushNotification(_ userInfo: [AnyHashable : Any]) -> Bool {
        Intercom.isIntercomPushNotification(userInfo)
    }

    func setDeviceToken(_ deviceToken: Data, failure: ((Error?) -> Void)? = nil) {
        Intercom.setDeviceToken(deviceToken, failure: failure)
    }
}
