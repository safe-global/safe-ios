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

    var theme = Theme()

    // Business Logic Layer

    var ens = ENS(registryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")

    // Data Layer

    // Services
    var safeRelayService = SafeRelayService(url: URL(string: "https://safe-relay.rinkeby.gnosis.io")!,
                                            logger: LogService.shared)
    
    var safeTransactionService = SafeTransactionService(url: URL(string: "https://safe-transaction.rinkeby.gnosis.io")!,
    logger: LogService.shared)

    var nodeService = EthereumNodeService(url: URL(string: "https://rinkeby.infura.io/v3/438e11915f8b4834a05e7810b88db4b3")!)
    
    private init() {}
}
