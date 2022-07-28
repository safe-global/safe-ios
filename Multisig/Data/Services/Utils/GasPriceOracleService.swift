//
// Created by Dirk Jäckel on 27.07.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
//import Json

class GasPriceOracleService {
    var url: URL
    var gasParameter: String
    private let httpClient: JSONHTTPClient

    var jsonDecoder: JSONDecoder {
        httpClient.jsonDecoder
    }

    init(url: URL, gasParameter: String, logger: Logger = LogService.shared) {
        self.url = url
        self.gasParameter = gasParameter
        httpClient = JSONHTTPClient(url: url, logger: logger)
        httpClient.jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
//        httpClient.jsonDecoder.keyDecodingStrategy = .custom { codingKeys in
//            Key(stringValue: gasParameter)!
//        }
    }

    @discardableResult
    func execute<T: JSONRequest>(request: T) throws -> T.ResponseType {
        try httpClient.execute(request: request)
    }

    func asyncExecute<T: JSONRequest>(request: T, completion: @escaping (Result<T.ResponseType, Error>) -> Void) -> URLSessionTask? {
        httpClient.asyncExecute(request: request, completion: completion)
    }
}

struct Key: CodingKey {

    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

//This should be a dynamic type with the gasParameter name. Maybe this can be done with CodingKey?
struct GasPriceOracleResponse: Decodable {
    var safeLow: String? = nil
    var standard: UInt256String?
    var fast: String?
    var fastest: String?
    var blockTime: String?
    var blockNumber: String?
}

struct GasPriceOracleRequest: JSONRequest {
    var httpMethod: String {
        "GET"
    }
    var urlPath: String {
        "/"
    }
//    typealias ResponseType = UInt256String
    typealias ResponseType = GasPriceOracleResponse
}