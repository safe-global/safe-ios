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

        @ConfigurationKey("CLAIMING_DATA_URL")
        var claimingDataURL: URL

        @ConfigurationKey("RELAY_URL")
        var relayURL: URL

        @ConfigurationKey("GELATO_SERVICE_URL")
        var gelatoRelayURL: URL

        @ConfigurationKey("MOONPAY_SERVICE_URL")
        var moonpayServiceURL: URL

        @ConfigurationKey("INFURA_API_KEY")
        var infuraKey: String

        @ConfigurationKey("INTERCOM_APP_ID")
        var intercomAppId: String

        @ConfigurationKey("INTERCOM_API_KEY")
        var intercomApiKey: String

        @ConfigurationKey("GNOSIS_SAFE_WEB_URL")
        var webAppURL: URL

        @ConfigurationKey("MOONPAY_API_KEY")
        var moonpayKey: String

        @ConfigurationKey("MOONPAY_SECRET_KEY")
        var moonpaySecretKey: String

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
        @ConfigurationKey("ADD_OWNERS_URL")
        var addOwnersURL: URL

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

        @ConfigurationKey("ADVANCED_TX_PARAMS_URL")
        var advancedTxParamsURL: URL

        @ConfigurationKey("DESKTOP_PAIRING_URL")
        var desktopPairingURL: URL

        @ConfigurationKey("DELEGATE_KEY_URL")
        var delegateKeyURL: URL

        @ConfigurationKey("LEDGER_PAIRING_URL")
        var ledgerPairingURL: URL

        @ConfigurationKey("CREATE_SAFE_URL")
        var createSafeURL: URL

        @ConfigurationKey("CONFIRMATIONS_URL")
        var confirmationsURL: URL

        @ConfigurationKey("RELAYER_INFO_URL")
        var relayerInfoURL: URL

        @ConfigurationKey("KEY_SECURITY_URL")
        var keySecurityURL: URL

        @ConfigurationKey("UNEXPECTED_DELEGATE_URL")
        var unexpectedDelegateURL: URL

        @ConfigurationKey("SOCIAL_LOGIN_INFO_URL")
        var socialLoginInfoURL: URL

        @ConfigurationKey("ONRAMPING_INFO_URL")
        var onrampingInfoURL: URL
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

        @ConfigurationKey("FORUM_URL")
        var forumURL: URL

        @ConfigurationKey("SAFE_DAO_URL")
        var safeDAOURL: URL
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

        @ConfigurationKey("WALLETCONNECT_REGISTRY_URL")
        var registryURL: URL

        @ConfigurationKey("WALLETCONNECT_PROJECT_ID")
        var walletConnectProjectId: String
    }

    struct FeatureToggles {
        @AppSetting(\.toggle_securityCenter)
        static var securityCenter: Bool
        
        static var socialLogin: Bool = false

        static var relay: Bool = true
    }

    struct Claim {
        @ConfigurationKey("CLAIM_DISCUSS_URL")
        var discussURL: URL

        @ConfigurationKey("CLAIM_PROPOSE_URL")
        var proposeURL: URL

        @ConfigurationKey("CLAIM_CHAT_URL")
        var chatURL: URL
    }

    struct Web3Auth {
        @ConfigurationKey("WEB3AUTH_GOOGLE_CLIENT_ID")
        var googleClientId: String

        @ConfigurationKey("WEB3AUTH_GOOGLE_VERIFIER_AGGREGATE")
        var googleVerifierAggregate: String

        @ConfigurationKey("WEB3AUTH_GOOGLE_VERIFIER_SUB")
        var googleVerifierSub: String

        @ConfigurationKey("WEB3AUTH_REDIRECT_SCHEME")
        var redirectScheme: String

        @ConfigurationKey("WEB3AUTH_APPLE_VERIFIER_AGGREGATE")
        var appleVerifier: String
        
        @ConfigurationKey("WEB3AUTH_APPLE_VERIFIER")
        var appleSubVerifier: String
    }

    let services = Services()
    let help = Help()
    let legal = Legal()
    let contact = Contact()
    let app = App()
    let walletConnect = WalletConnect()
    let claim = Claim()
    let web3auth = Web3Auth()
}
