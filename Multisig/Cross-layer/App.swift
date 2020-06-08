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

    var viewState = ViewState()
    var theme = Theme()

    // Business Logic Layer

    var ens = ENS(registryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
    var gnosisSafe = GnosisSafe()

    // Data Layer

    // Services    
    var safeTransactionService = SafeTransactionService(
        url: configuration.services.transactionServiceURL,
        logger: LogService.shared)

    var nodeService = EthereumNodeService(url: configuration.services.ethereumServiceURL)

    var coreDataStack: CoreDataProtocol = CoreDataStack()

    let defaultFallbackHandler = Address("0xd5D82B6aDDc9027B22dCA772Aa68D5d74cdBdF44")

    // Cross-layer
    static let configuration = AppConfiguration()

    private init() {}
}
