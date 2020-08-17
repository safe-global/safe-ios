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

        @ConfigurationKey("TRANSACTION_SERVICE_URL")
        var transactionServiceURL: URL

        @ConfigurationKey("CLIENT_GATEWAY_URL")
        var clientGatewayURL: URL

        @ConfigurationKey("ETH_RPC_URL")
        var ethereumServiceURL: URL

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
    }

    struct App {
        @ConfigurationKey("CFBundleShortVersionString")
        var marketingVersion: String

        @ConfigurationKey("CFBundleVersion")
        var buildVersion: String

        @ConfigurationKey("CFBundleIdentifier")
        var bundleIdentifier: String

        @ConfigurationKey("NETWORK")
        var network: Network

        @ConfigurationKey("LOGGERS")
        var loggers: String

        @ConfigurationKey("LOG_LEVEL")
        var logLevel: String
    }

    let services = Services()
    let legal = Legal()
    let contact = Contact()
    let app = App()
}

enum Network: String, InfoPlistValueType {
    case mainnet = "Mainnet"
    case rinkeby = "Rinkeby"

    static func convert(from value: Any) -> Self {
        (value as? String).flatMap { Self(rawValue: $0.capitalized) } ?? .mainnet
    }
}
