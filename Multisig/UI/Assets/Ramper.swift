//
//  OnrampingFlow.swift
//  Multisig
//
//  Created by Vitaly on 19.07.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import MoonpaySDK

class Ramper: MoonpayCallbackInterface {

    let MOONPAY_THEME_ID_SAFE = "7e8968f6-99a4-43b5-8286-d3c290d3a0b2"

    func startOnRamp() {
        let moonpay = MoonpaySDK()

        var theme = "light"
        if UIScreen.main.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark || App.shared.theme.displayMode == UIUserInterfaceStyle.dark {
            theme = "dark"
        }

        moonpay.doInit(
            apiKey: App.configuration.services.moonpayKey,
            debugLevel: MoonpayDebug.info,
            flow: MoonpayFlow.buy,
            environment: MoonpayEnvironment.sandbox,
            properties: [
                // use safe theme in light and dark mode
                MoonpayOptions.themeid: MOONPAY_THEME_ID_SAFE,
                MoonpayOptions.theme: theme,
                // prevent using device localisation by explicitly setting interface language
                MoonpayOptions.language: "en"
            ],
            rendering: MoonpayRenderingiOS.webviewoverlay,
            delegate: self
        )

        moonpay.show()
    }

    func startOffRamp() {

    }

    func hasLoadedWeb() {

    }

    func receivedMessage(message: Any) {

    }
}
