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
        Intercom.registerUnidentifiedUser()

        disableChatOverlay()
    }

    func disableChatOverlay() {
        Intercom.setInAppMessagesVisible(false)
    }

    func startChat() {
        Intercom.presentMessenger()
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
}
