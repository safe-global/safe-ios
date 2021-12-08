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

        disableChatOverlay()
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
}