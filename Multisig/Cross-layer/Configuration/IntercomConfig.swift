//
// Created by Dirk Jäckel on 23.11.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import Intercom

class IntercomConfig {

    func setUp() {
        Intercom.setApiKey(App.configuration.services.intercomApiKey, forAppId: App.configuration.services.intercomAppId)

        #if DEBUG
        Intercom.enableLogging()
        #endif
        Intercom.registerUnidentifiedUser()

        disableChatOverlay() // enable only where appropriate

        NotificationCenter.default.addObserver(self,
                selector: #selector(IntercomConfig.updateUnreadCount(_:)),
                name: NSNotification.Name.IntercomUnreadConversationCountDidChange,
                object: nil)

    }

    @objc func updateUnreadCount(_ count: UInt) {
        print("FOOOOOOOOOOOOOOOOOOO: \(count)")
    }

    func disableFAB() {
        Intercom.setLauncherVisible(false)
    }

    func enableFAB() {
        Intercom.setBottomPadding(30)
        Intercom.setLauncherVisible(true)
    }


    func disableChatOverlay() {
        Intercom.setInAppMessagesVisible(false)
    }

    func enableChatOverlay() {
        Intercom.setInAppMessagesVisible(true)
    }
}