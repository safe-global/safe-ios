//
// Created by Dmitry Bespalov on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct WCGetDappsRequest: JSONRequest {
    var httpMethod: String { "GET" }
    var urlPath: String { "/safe-ios-wc-registry/data/dapps.json" }

    typealias ResponseType = JsonAppRegistry
}

extension WCRegistryService {
    func asyncDapps(completion: @escaping (Result<JsonAppRegistry, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: WCGetDappsRequest(), completion: completion)
    }
}
