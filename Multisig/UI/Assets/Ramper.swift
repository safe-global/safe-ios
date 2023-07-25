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

    private let MOONPAY_THEME_ID_SAFE = "7e8968f6-99a4-43b5-8286-d3c290d3a0b2"
    private let moonpay: MoonpaySDK

    init() {
        moonpay = MoonpaySDK()
    }

    func startOnRamp(safe: Safe) {
        guard let chain = safe.chain else { return }
        var theme = "light"
        // use dark safe theme if appearance app setting is set to dark
        // or if appearance app setting is set to auto and device uses dark mode
        if UIScreen.main.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark || App.shared.theme.displayMode == UIUserInterfaceStyle.dark {
            theme = "dark"
        }


        // TODO: enable production envoronment on production and sandbox on staging 
        let moonpayDebugLevel = MoonpayDebug.info
        let moonpayEnv = MoonpayEnvironment.sandbox

//        let moonpayDebugLevel = MoonpayDebug.error
//        let moonpayEnv = MoonpayEnvironment.production


        // Reference: https://docs.moonpay.com/moonpay/developer-resources/sdks/ios-sdk/customize-the-widget
        moonpay.doInit(
            apiKey: App.configuration.services.moonpayKey,
            debugLevel: moonpayDebugLevel,
            flow: MoonpayFlow.buy,
            environment: moonpayEnv,
            properties: [
                // use safe theme in light and dark mode
                MoonpayOptions.themeid: MOONPAY_THEME_ID_SAFE,
                MoonpayOptions.theme: theme,
                // prevent using device localisation by explicitly setting interface language
                MoonpayOptions.language: "en",
                // preselect default chain currency if available via moonpay
                MoonpayOptions.defaultcurrencycode: chain.nativeCurrency!.symbol!,
                // the purchased funds will be sent to the selected safe account
                MoonpayOptions.walletaddresses: "{\"\(chain.shortName!)\":\"\(safe.address!)\"}",
                // preselect user's default fiat currency
                MoonpayOptions.basecurrencycode: AppSettings.selectedFiatCode
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
