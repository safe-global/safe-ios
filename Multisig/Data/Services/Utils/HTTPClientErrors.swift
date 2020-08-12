//
//  HTTPClientErrors.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

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
            LogService.shared.error(
                "Missing data in unprocessableEntity error",
                error: HTTPClientUnexpectedError.missingDataInUnprocessableEntity
            )
            return UnexpectedError(code: UnexpectedError.unprocessableEntityMissingData)
        }
        do {
            let error = try JSONDecoder().decode(BackendError.self, from: data)
            switch error.code {
            case 1:
                return InvalidChecksum()
            case 50:
                return SafeInfoNotFound()
            default:
                LogService.shared.error(
                    "Unrecognised error code: \(error.code)",
                    error: HTTPClientUnexpectedError.unrecognizedErrorCode(error.code)
                )
                return UnexpectedError(code: error.code)
            }
        } catch {
            let dataString = String(data: data, encoding: .utf8) ?? data.base64EncodedString()
            LogService.shared.error(
                "Could not decode error details from the data: \(dataString)",
                error: HTTPClientUnexpectedError.errorDetailsDecodingFailed(dataString)
            )
            return UnexpectedError(code: UnexpectedError.failedToDecodeErrorDetails) // code Z
        }
    }

    private static func unknownError(_ request: URLRequest, _ response: URLResponse?, _ data: Data?) -> Error {
        let requestStr = String(describing: request)
        let responseStr = response.map { String(describing: $0) } ?? "<no response>"
        let dataStr = data.map { String(data: $0, encoding: .utf8) ?? $0.base64EncodedString() } ?? "<no data>"
        let msg = "Unknown HTTP error. Request: \(requestStr); Response: \(responseStr); Data: \(dataStr)"
        LogService.shared.error(
            msg,
            error: HTTPClientUnexpectedError.unknownHTTPError(msg)
        )
        return UnexpectedError(code: UnexpectedError.unknownError)
    }

    fileprivate struct BackendError: Decodable {
        let code: Int
        let message: String
    }

    struct NetworkRequestFailed: LocalizedError {
        var errorDescription: String? {
            "The network request failed. Please try out later."
        }
    }

    struct EntityNotFound: LocalizedError {
        var errorDescription: String? {
            "Entity not found."
        }
    }

    struct InvalidChecksum: LocalizedError {
        var errorDescription: String? {
            "Checksum address validation failed."
        }
    }

    struct SafeInfoNotFound: LocalizedError {
        var errorDescription: String? {
            "Safe info is not found."
        }
    }

    struct UnexpectedError: LocalizedError {
        let code: Int

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
