//
// Created by Dmitry Bespalov on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct WCGetWalletsRequest: JSONRequest {
    var httpMethod: String { "GET" }
    var urlPath: String { "/safe-ios-wc-registry/data/wallets.json" }

    typealias ResponseType = JsonAppRegistry
}

extension WCRegistryService {
    func asyncWallets(completion: @escaping (Result<JsonAppRegistry, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: WCGetWalletsRequest(), completion: completion)
    }
}
