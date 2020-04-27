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

    // Data Layer

    // Services
    var safeRelayService = SafeRelayService(url: URL(string: "https://safe-relay.rinkeby.gnosis.io")!,
                                            logger: LogService.shared)
}
