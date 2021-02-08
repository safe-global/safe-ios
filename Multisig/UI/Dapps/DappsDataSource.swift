//
//  DappsDataSource.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 05.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct DappData: Decodable {
    let name: String
    let description: String
    let logo: URL
    let url: URL
}

/**
 Only quite old dapps with old WC lib are supported at the moment.

 Dapps without mobile-to-mobile WC support.
 - Safe
 - Compound
 - Sushiswap
 - 1inch.exchange
 - aave
 - Balancer
 - dHedge
 - Sablier (no WC on mobile at all)
 - Synthetix (seems like working on their own mobile app)
 - Yearn
 - Badger.Finance
 - Curve
 - dYdX
 -
 */

class DappsDataSource {
    static let shared = DappsDataSource()

    let dapps: [DappData]

    init() {
        let path: String
        if App.configuration.app.network == .mainnet {
            path = Bundle.main.path(forResource: "dapps-mainnet", ofType: "json")!
        } else {
            path = Bundle.main.path(forResource: "dapps-rinkeby", ofType: "json")!
        }
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        dapps = try! JSONDecoder().decode([DappData].self, from: data)
    }
}
