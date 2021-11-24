//
// Created by Dirk Jäckel on 23.11.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import Intercom

class IntercomConfig {

    func setUp() {
        Intercom.setApiKey(App.configuration.services.intercomApiKey, forAppId: App.configuration.services.intercomAppId)
        Intercom.setLauncherVisible(true)

        #if DEBUG
        Intercom.enableLogging()
        #endif
        Intercom.registerUnidentifiedUser()
    }

}