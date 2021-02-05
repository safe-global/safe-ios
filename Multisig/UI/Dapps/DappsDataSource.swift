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
        let path = Bundle.main.path(forResource: "dapps", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        dapps = try! JSONDecoder().decode([DappData].self, from: data)
    }
}
