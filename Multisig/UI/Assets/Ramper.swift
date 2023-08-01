//
//  OnrampingFlow.swift
//  Multisig
//
//  Created by Vitaly on 19.07.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import MoonpaySDK
import Foundation
import CryptoSwift

class Ramper: MoonpayCallbackInterface {

    private let MOONPAY_THEME_ID_SAFE = "7e8968f6-99a4-43b5-8286-d3c290d3a0b2"
    private let moonpay: MoonPayiOSSdk

    private var address: String!
    private var chain: Chain!
    private var currencies: [MoonpayModels.Currency] = []

    static let shared = Ramper()

    init() {
        moonpay = MoonPayiOSSdk()
    }

    func config() {
        currencies = (try? App.shared.moonpayService.syncCurrenciesRequest()) ?? []
    }

    func startOnRamp(address: String, chain: Chain) {
        self.address = address
        self.chain = chain

        var theme = "light"
        // use dark safe theme if appearance app setting is set to dark
        // or if appearance app setting is set to auto and device uses dark mode
        if UIScreen.main.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark || App.shared.theme.displayMode == UIUserInterfaceStyle.dark {
            theme = "dark"
        }

        let environment = App.configuration.services.environment == .production ? WidgetEnvironment.production : WidgetEnvironment.sandbox
        let signature = sigature(address: address,
                                 chain: chain.shortName!,
                                 theme: theme,
                                 defaultCurrencyCode: chain.nativeCurrency!.symbol!,
                                 environment: environment.description().lowercased())

        let params = OnrampWidgetQueryParams(
            apiKey: App.configuration.services.moonpayKey,
            currencyCode: nil,
            defaultCurrencyCode: chain.nativeCurrency!.symbol!,
            walletAddress: nil,
            walletAddressTag: nil,
            walletAddresses: walletAddresses(),
            walletAddressTags: nil,
            colorCode: nil,
            theme: theme,
            themeId: MOONPAY_THEME_ID_SAFE,
            language: "en",
            signature: signature,
            baseCurrencyCode: AppSettings.selectedFiatCode,
            baseCurrencyAmount: nil,
            quoteCurrencyAmount: nil,
            lockAmount: nil,
            email: nil,
            externalTransactionId: nil,
            externalCustomerId: nil,
            paymentMethod: nil,
            redirectURL: nil,
            showAllCurrencies: nil,
            showOnlyCurrencies: nil,
            showWalletAddressForm: nil,
            unsupportedRegionRedirectUrl: nil,
            skipUnsupportedRegionScreen: nil
        )

        let config = MoonPayCoreSdkBuyConfig(
            debug: true,
            environment: environment,
            flow: BuyFlow(),
            params: params,
            handlers: nil
        )

        moonpay.doInit(config: config)
        moonpay.show(mode: .WebViewOverlay())
    }

    func startOffRamp() {

    }

    func hasLoadedWeb() {

    }

    func receivedMessage(message: Any) {

    }

    private func sigature(address: String, chain: String, theme: String, defaultCurrencyCode: String, environment: String) -> String {
        let bytes = Array( "?apiKey=\(App.configuration.services.moonpayKey)&defaultCurrencyCode=\(defaultCurrencyCode)&walletAddresses=%7B%22\(chain)%22%3A%22\(address)%22%7D&theme=\(theme)&themeId=\(MOONPAY_THEME_ID_SAFE)&language=en&baseCurrencyCode=\(AppSettings.selectedFiatCode)&mpSdk=%7B%22environment%22%3A%22\(environment)%22%2C%22flow%22%3A%22buy%22%2C%22version%22%3A%221.0%22%2C%22platform%22%3A%22iOS%22%7D".utf8)

        let key: Array<UInt8> = Array(App.configuration.services.moonpaySecretKey.utf8)

        return Data(try! HMAC(key: key, variant: .sha2(.sha256)).authenticate(bytes)).base64EncodedString()
    }

    private func walletAddresses() -> String {
        "{\"\(chain.shortName!)\":\"\(address!)\"}"
    }
}
