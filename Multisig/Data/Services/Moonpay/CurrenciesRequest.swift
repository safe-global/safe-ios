//
//  CurrenciesRequest.swift
//  Multisig
//
//  Created by Mouaz on 8/1/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CurrenciesRequest: JSONRequest {
    var httpMethod: String { "GET" }

    var urlPath: String {
        "/v3/currencies"
    }

    var query: String? {
        "apiKey=\(App.configuration.services.moonpayKey)"
    }

    typealias ResponseType = [MoonpayModels.Currency]
}

extension MoonpayService {
    @discardableResult
    func asyncCurrenciesRequest(completion: @escaping (Result<CurrenciesRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: CurrenciesRequest(), completion: completion)
    }

    func syncCurrenciesRequest() throws -> [MoonpayModels.Currency] {
        try execute(request: CurrenciesRequest())
    }
}
