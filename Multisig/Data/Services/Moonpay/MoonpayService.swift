//
//  MoonpayService.swift
//  Multisig
//
//  Created by Mouaz on 8/1/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

class MoonpayService {
    var url: URL
    private let httpClient: JSONHTTPClient

    var jsonDecoder: JSONDecoder {
        httpClient.jsonDecoder
    }

    init(url: URL, logger: Logger) {
        self.url = url
        httpClient = JSONHTTPClient(url: url, logger: logger)
        httpClient.jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
    }

    @discardableResult
    func execute<T: JSONRequest>(request: T) throws -> T.ResponseType {
        try httpClient.execute(request: request)
    }

    func asyncExecute<T: JSONRequest>(request: T, completion: @escaping (Result<T.ResponseType, Error>) -> Void) -> URLSessionTask? {
        httpClient.asyncExecute(request: request, completion: completion)
    }
}
