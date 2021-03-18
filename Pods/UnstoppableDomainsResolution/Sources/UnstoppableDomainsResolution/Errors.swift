//
//  Errors.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public enum ResolutionError: Error {
    case unregisteredDomain
    case unsupportedDomain
    case recordNotFound
    case recordNotSupported
    case unsupportedNetwork
    case unspecifiedResolver
    case unknownError(Error)
    case proxyReaderNonInitialized
    case inconsistenDomainArray
    case methodNotSupported
    case tooManyResponses
    case badRequestOrResponse
    case unsupportedServiceName

    static let tooManyResponsesCode = -32005
    static let badRequestOrResponseCode = -32042

    static func parse (errorResponse: NetworkErrorResponse) -> ResolutionError? {
        let error = errorResponse.error
        if error.code == tooManyResponsesCode {
            return .tooManyResponses
        }
        if error.code == badRequestOrResponseCode {
            return .badRequestOrResponse
        }
        return nil
    }
}

struct NetworkErrorResponse: Decodable {
    var jsonrpc: String
    var id: String
    var error: ErrorId
}

struct ErrorId: Codable {
    var code: Int
    var message: String
}
