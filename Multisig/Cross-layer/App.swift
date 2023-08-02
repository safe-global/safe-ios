//
//  App.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class App {
    static let shared = App()

    // MARK: - UI layer

    let viewState = ViewState()
    let theme = Theme()
    let snackbar = SnackbarCenter()
    let appReview = AppReviewController()
    let updateController = UpdateController()

    // MARK: - Business Logic Layer

    let gnosisSafe = GnosisSafe()
    let auth = AuthenticationController()

    // MARK: - Data Layer

    var coreDataStack: CoreDataProtocol = CoreDataStack()
    var keychainService: SecureStore = KeychainService(identifier: App.configuration.app.bundleIdentifier)

    let securityCenter: SecurityCenter = SecurityCenter.shared

    // MARK: - Services

    // It should be lazy as it uses Firebase and coreDataStack that are not yet properly initialized
    lazy var clientGatewayService = SafeClientGatewayService(
        url: App.configuration.services.clientGatewayURL,
        logger: LogService.shared)

    lazy var claimingService = SafeClaimingService(
        url: App.configuration.services.claimingDataURL,
        logger: LogService.shared
    )

    lazy var relayService = SafeGelatoRelayService(
        url: App.configuration.services.relayURL,
        logger: LogService.shared
    )

    lazy var gelatoRelayService = GelatoRelayService(
        url: App.configuration.services.gelatoRelayURL,
        logger: LogService.shared
    )

    lazy var moonpayService = MoonpayService(
        url: App.configuration.services.moonpayServiceURL,
        logger: LogService.shared
    )
    
    var nodeService = EthereumNodeService()

    let notificationHandler = RemoteNotificationHandler()

    let clientGatewayHostObserver = NetworkHostStatusObserver(host: configuration.services.clientGatewayURL.host ?? "www.gnosis.io")

    lazy var walletConnectRegistryService = WCRegistryService(
        url: App.configuration.walletConnect.registryURL,
        logger: LogService.shared)

    lazy var ramper = Ramper.shared

    // MARK: - Cross-layer

    static let configuration = AppConfiguration()

    let firebaseConfig = FirebaseConfig()

    private init() {}
}
