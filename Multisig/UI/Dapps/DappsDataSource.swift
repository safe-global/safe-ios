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
    static let shared = DappsDataSource()

    let dapps: [DappData]

    init() {
        let network = try? Safe.getSelected()?.network
        assert(network != nil, "Developer error: expect to have selected safe with network")
        let path: String
        if network!.id == 1 {
            path = Bundle.main.path(forResource: "dapps-mainnet", ofType: "json")!
        } else {
            path = Bundle.main.path(forResource: "dapps-rinkeby", ofType: "json")!
        }
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        dapps = try! JSONDecoder().decode([DappData].self, from: data)
    }
}
