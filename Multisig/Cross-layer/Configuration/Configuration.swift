//
//  Configuration.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 08.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct AppConfiguration {

    struct Services {
        @ConfigurationKey("SERVICE_ENV")
        var environment: ServiceEnvironment

        @ConfigurationKey("CLIENT_GATEWAY_URL")
        var clientGatewayURL: URL

        @ConfigurationKey("INFURA_API_KEY")
        var infuraKey: String

        #warning("TODO: remove")
        @ConfigurationKey("ETH_BLOCK_BROWSER_URL")
        var etehreumBlockBrowserURL: URL

        @ConfigurationKey("GNOSIS_SAFE_WEB_URL")
        var webAppURL: URL

        enum ServiceEnvironment: String, InfoPlistValueType {
            case development = "DEV"
            case staging = "STAGING"
            case production = "PROD"

            static func convert(from value: Any) -> Self {
                (value as? String).flatMap { Self(rawValue: $0) } ?? .production
            }
        }
    }

    struct Help {
        @ConfigurationKey("CONFLICT_URL")
        var conflictURL: URL

        @ConfigurationKey("FALLBACKHANDLER_URL")
        var fallbackHandlerURL: URL

        @ConfigurationKey("GUARD_URL")
        var guardURL: URL

        @ConfigurationKey("PAY_FOR_CANCELLATION_URL")
        var payForCancellationURL: URL

        @ConfigurationKey("CONNECT_DAPP_ON_MOBILE_URL")
        var connectDappOnMobileURL: URL
    }

    struct Legal {
        @ConfigurationKey("TERMS_URL")
        var termsURL: URL

        @ConfigurationKey("PRIVACY_URL")
        var privacyURL: URL

        @ConfigurationKey("LICENSES_URL")
        var licensesURL: URL
    }

    struct Contact {
        @ConfigurationKey("DISCORD_URL")
        var discordURL: URL

        @ConfigurationKey("TWITTER_URL")
        var twitterURL: URL

        @ConfigurationKey("HELP_CENTER_URL")
        var helpCenterURL: URL

        @ConfigurationKey("FEATURE_SUGGESTION_URL")
        var featureSuggestionURL: URL

        @ConfigurationKey("CONTACT_EMAIL")
        var contactEmail: URL

        @ConfigurationKey("APP_STORE_REVIEW_URL")
        var appStoreReviewURL: URL
    }

    struct App {
        @ConfigurationKey("CFBundleShortVersionString")
        var marketingVersion: String

        @ConfigurationKey("CFBundleVersion")
        var buildVersion: String

        @ConfigurationKey("CFBundleIdentifier")
        var bundleIdentifier: String

        @ConfigurationKey("LOGGERS")
        var loggers: String

        @ConfigurationKey("LOG_LEVEL")
        var logLevel: String
    }

    struct WalletConnect {
        @ConfigurationKey("WALLETCONNECT_BRIDGE_URL")
        var bridgeURL: URL
    }

    struct FeatureToggles {
        @UserDefault(key: "io.gnosis.multisig.experimental.walletConnect")
        private var walletConnectEnabledSetting: Bool?

        @UserDefault(key: "io.gnosis.multisig.experimental.walletConnectOwnerKey")
        private var walletConnectOwnerKeyEnabledSetting: Bool?

        var walletConnectEnabled: Bool {
            return walletConnectEnabledSetting ?? false
        }

        var walletConnectOwnerKeyEnabled: Bool {
            return walletConnectOwnerKeyEnabledSetting ?? false
        }
    }

    let services = Services()
    let help = Help()
    let legal = Legal()
    let contact = Contact()
    let app = App()
    let walletConnect = WalletConnect()
    let toggles = FeatureToggles()
}
