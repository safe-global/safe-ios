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
        return App.configuration.services.webAppURL.appendingPathComponent("\(chainPrefix):\(safe.description)/balances/collectibles")
    }
}
