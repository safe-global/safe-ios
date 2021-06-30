//
//  SafeClientGatewayService.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class SafeClientGatewayService {
    var url: URL
    var chainId: Int! = 1
    private let httpClient: JSONHTTPClient

    var jsonDecoder: JSONDecoder {
        httpClient.jsonDecoder
    }

    init(url: URL, logger: Logger) {
        self.url = url
        httpClient = JSONHTTPClient(url: url, logger: logger)
        httpClient.jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
    }

    func bindNetwork(_ chainId: Int) {
        self.chainId = chainId
    }

    @discardableResult
    func execute<T: JSONRequest>(request: T) throws -> T.ResponseType {
        try httpClient.execute(request: request)
    }

    func asyncExecute<T: JSONRequest>(request: T, completion: @escaping (Result<T.ResponseType, Error>) -> Void) -> URLSessionTask? {
        httpClient.asyncExecute(request: request, completion: completion)
    }
}
