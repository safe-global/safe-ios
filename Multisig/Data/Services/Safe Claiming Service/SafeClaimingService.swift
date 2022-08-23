//
//  SafeClaimingService.swift
//  Multisig
//
//  Created by Mouaz on 8/11/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
class SafeClaimingService {
    var url: URL
    private let httpClient: JSONHTTPClient

    var jsonDecoder: JSONDecoder {
        httpClient.jsonDecoder
    }

    init(logger: Logger) {
        self.url = URL(string: "https://5afe.github.io/")!
        httpClient = JSONHTTPClient(url: url, logger: logger)
        httpClient.jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
        httpClient.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    @discardableResult
    func execute<T: JSONRequest>(request: T) throws -> T.ResponseType {
        try httpClient.execute(request: request)
    }

    func asyncExecute<T: JSONRequest>(request: T, completion: @escaping (Result<T.ResponseType, Error>) -> Void) -> URLSessionTask? {
        httpClient.asyncExecute(request: request, completion: completion)
    }
}
