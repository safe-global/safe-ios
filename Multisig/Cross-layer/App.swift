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

    // Business Logic Layer

    let ens = ENS(registryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
    let gnosisSafe = GnosisSafe()

    // Data Layer

    var coreDataStack: CoreDataProtocol = CoreDataStack()

    let keychainService = KeychainService(identifier: App.configuration.app.bundleIdentifier)

    // Services    ∫
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

    // Cross-layer
    static let configuration = AppConfiguration()

    let firebaseConfig = FirebaseConfig()

    private init() {}
}
