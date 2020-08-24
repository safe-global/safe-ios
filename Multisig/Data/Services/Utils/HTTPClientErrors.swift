//
//  HTTPClientErrors.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

fileprivate let errorDomain = "HTTPClientError"

enum HTTPClientError {

    static func error(_ request: URLRequest, _ response: URLResponse?, _ data: Data?) -> Error {
        guard let httpResponse = response as? HTTPURLResponse else {
            return UnexpectedError(code: UnexpectedError.httpResponseMissing)
        }
        switch httpResponse.statusCode {
        case 200...299:
            assertionFailure("Not an error, please check the calling code")
            return UnexpectedError(code: UnexpectedError.notAnError)
        case 404:
            return EntityNotFound()
        case 422:
            return unprocessableEntity(request, response, data)
        default:
            return unknownError(request, response, data)
        }
    }

    private static func unprocessableEntity(_ request: URLRequest, _ response: URLResponse?, _ data: Data?) -> Error {
        guard let data = data else {
            let error = UnexpectedError(code: UnexpectedError.unprocessableEntityMissingData)
            LogService.shared.error(
                "Missing data in unprocessableEntity error",
                error: error
            )
            return error
        }
        do {
            let error = try JSONDecoder().decode(BackendError.self, from: data)
            switch error.code {
            case 1:
                return InvalidChecksum()
            case 50:
                return SafeInfoNotFound()
            default:
                let error = UnexpectedError(code: error.code)
                LogService.shared.error(
                    "Unrecognised error code: \(error.code)",
                    error: error
                )
                return error
            }
        } catch {
            let dataString = String(data: data, encoding: .utf8) ?? data.base64EncodedString()
            let error = UnexpectedError(code: UnexpectedError.failedToDecodeErrorDetails)
            LogService.shared.error(
                "Could not decode error details from the data: \(dataString)",
                error: error
            )
            return error
        }
    }

    private static func unknownError(_ request: URLRequest, _ response: URLResponse?, _ data: Data?) -> Error {
        let requestStr = String(describing: request)
        let responseStr = response.map { String(describing: $0) } ?? "<no response>"
        let dataStr = data.map { String(data: $0, encoding: .utf8) ?? $0.base64EncodedString() } ?? "<no data>"
        let msg = "Unknown HTTP error. Request: \(requestStr); Response: \(responseStr); Data: \(dataStr)"
        let error = UnexpectedError(code: UnexpectedError.unknownError)
        LogService.shared.error(msg, error: error)
        return error
    }

    fileprivate struct BackendError: Decodable {
        let code: Int
        let message: String
    }

    struct NetworkRequestFailed: LocalizedError, LoggableError {
        var errorDescription: String? {
            "The network request failed. Please try out later."
        }
        let domain = errorDomain
        let code = -80001
    }

    struct EntityNotFound: LocalizedError, LoggableError {
        var errorDescription: String? {
            "Entity not found."
        }
        let domain = errorDomain
        let code = -80404
    }

    struct InvalidChecksum: LocalizedError, LoggableError {
        var errorDescription: String? {
            "Checksum address validation failed."
        }
        let domain = errorDomain
        let code = -80402
    }

    struct SafeInfoNotFound: LocalizedError, LoggableError {
        var errorDescription: String? {
            "Safe info is not found."
        }
        let domain = errorDomain
        let code = -80004
    }

    struct UnexpectedError: LocalizedError, LoggableError {
        var code: Int
        let domain = errorDomain

        var errorDescription: String? {
            "Unexpected error \(code). We are notified and will try to fix it asap."
        }

        static let unprocessableEntityMissingData   = -9942201
        static let failedToDecodeErrorDetails       = -9942202
        static let httpResponseMissing              = -9900001
        static let unknownError                     = -9900002
        static let notAnError                       = -9900000
    }

}
