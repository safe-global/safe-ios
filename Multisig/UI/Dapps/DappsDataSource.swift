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

class DappsDataSource {
    let dapps: [DappData]

    init() {
        guard let chain = try? Safe.getSelected()?.chain else {
            // it may happen that the data was deleted and we get updated from a notifictaion.
            dapps = []
            return
        }

        let path: String
        switch chain.id {
        case Chain.ChainID.ethereumMainnet: path = Bundle.main.path(forResource: "dapps-mainnet", ofType: "json")!
        case Chain.ChainID.ethereumRinkeby: path = Bundle.main.path(forResource: "dapps-rinkeby", ofType: "json")!
        case Chain.ChainID.polygon: path = Bundle.main.path(forResource: "dapps-polygon", ofType: "json")!
        case Chain.ChainID.gnosis: path = Bundle.main.path(forResource: "dapps-xdai", ofType: "json")!
        case Chain.ChainID.bsc: path = Bundle.main.path(forResource: "dapps-bsc", ofType: "json")!
        case Chain.ChainID.arbitrum: path = Bundle.main.path(forResource: "dapps-arbitrum", ofType: "json")!
        case Chain.ChainID.optimism: path = Bundle.main.path(forResource: "dapps-optimism", ofType: "json")!
        case Chain.ChainID.avalanche: path = Bundle.main.path(forResource: "dapps-avalanche", ofType: "json")!

        default:
            dapps = []
            return
        }

        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        dapps = try! JSONDecoder().decode([DappData].self, from: data)
    }
}
