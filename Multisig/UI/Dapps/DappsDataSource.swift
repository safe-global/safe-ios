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
            assertionFailure("Developer error: expect to have selected safe with network")
            dapps = []
            return
        }

        let path: String
        switch chain.id {
        case Chain.ChainID.ethereumMainnet: path = Bundle.main.path(forResource: "dapps-mainnet", ofType: "json")!
        case Chain.ChainID.ethereumRinkeby: path = Bundle.main.path(forResource: "dapps-rinkeby", ofType: "json")!
        case Chain.ChainID.polygon: path = Bundle.main.path(forResource: "dapps-polygon", ofType: "json")!
        case Chain.ChainID.xDai: path = Bundle.main.path(forResource: "dapps-xdai", ofType: "json")!
        default:
            dapps = []
            return
        }

        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        dapps = try! JSONDecoder().decode([DappData].self, from: data)
    }
}
