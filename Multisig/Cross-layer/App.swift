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

    // UI layer
    let viewState = ViewState()
    let theme = Theme()
    let snackbar = SnackbarCenter()

    let appReview = AppReviewController()

    let updateController = UpdateController()
    // Business Logic Layer

    let blockchainDomainManager = BlockchainDomainManager()
    let gnosisSafe = GnosisSafe()
    let auth = AuthenticationController()

    // Data Layer
    var coreDataStack: CoreDataProtocol = CoreDataStack()

    var keychainService: SecureStore = KeychainService(identifier: App.configuration.app.bundleIdentifier)

    // Services
    let safeTransactionService = SafeTransactionService(
        url: configuration.services.transactionServiceURL,
        logger: LogService.shared)

    let clientGatewayService = SafeClientGatewayService(
        url: configuration.services.clientGatewayURL,
        logger: LogService.shared)

    let nodeService = EthereumNodeService(
        url: configuration.services.ethereumServiceURL)

    let tokenRegistry = TokenRegistry()

    let notificationHandler = RemoteNotificationHandler()

    let clientGatewayHostObserver = NetworkHostStatusObserver(host: configuration.services.clientGatewayURL.host ?? "www.gnosis.io")

    // Cross-layer
    static let configuration = AppConfiguration()

    let firebaseConfig = FirebaseConfig()

    private init() {}
}
