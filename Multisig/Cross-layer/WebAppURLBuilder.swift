//
//  WebAppURLBuilder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

enum WebAppURLBuilder {
    static func url(safe: Address, chainPrefix: String) -> URL? {
        let path = "https://gnosis-safe.io/app/\(chainPrefix):\(safe.description)/balances/collectibles"
        return URL(string: path)
    }
}
