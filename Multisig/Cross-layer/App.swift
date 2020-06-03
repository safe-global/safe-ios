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
    var safeTransactionService = SafeTransactionService(url: URL(string: "https://safe-transaction.rinkeby.gnosis.io")!,
    logger: LogService.shared)

    var nodeService = EthereumNodeService(url: URL(string: "https://rinkeby.infura.io/v3/438e11915f8b4834a05e7810b88db4b3")!)

    var coreDataStack: CoreDataProtocol = CoreDataStack()

    var browseAddressURL = "https://rinkeby.etherscan.io/address/"
    
    let termOfUseURL = URL(string:"https://gnosis-safe.io/terms/")!
    let privacyPolicyURL = URL(string:"https://gnosis-safe.io/privacy/")!
    let licensesURL = URL(string:"https://gnosis-safe.io/licenses/")!
    let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) (\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String))"

    let defaultFallbackHandler = Address("0xd5D82B6aDDc9027B22dCA772Aa68D5d74cdBdF44")
    
    let network: Network = .rinkeby
    
    private init() {}
}

enum Network: String {
    case mainnet = "Mainnet"
    case rinkeby = "Rinkeby"
}
