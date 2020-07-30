//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

protocol HTTPRequest {
    var httpMethod: String { get }
    var urlPath: String { get }
    var query: String? { get }
    var body: Data? { get }
    var headers: [String: String] { get }
}

extension HTTPRequest {
    var query: String? { return nil }
    var body: Data? { return nil }
    var headers: [String: String] { return [:] }
}

/// Synchronous http client
class HTTPClient {
    private let baseURL: URL
    private let logger: Logger?

    private typealias URLDataTaskResult = (data: Data?, response: URLResponse?, error: Swift.Error?)

    /// Creates new client with baseURL and logger
    ///
    /// - Parameters:
    ///   - url: base url for creating all request urls
    ///   - logger: logger for debugging and error purposes
    init(url: URL, logger: Logger? = nil) {
        baseURL = url
        self.logger = logger
    }

    fileprivate enum UnexpectedError: LoggableError {
        case unrecognizedErrorCode(Int)
        case missingDataInUnprocessableEntity
        case errorDetailsDecodingFailed(String)
        case unknownHTTPError(String)
    }

    enum Error: LocalizedError {
        case networkRequestFailed(URLRequest, URLResponse?, Data?)
        case entityNotFound(URLRequest, URLResponse?, Data?)
        case unprocessableEntity(URLRequest, URLResponse?, Data?)
        case unknownError(URLRequest, URLResponse?, Data?)

        enum Message: String {
            case networkRequestFailed = "The network request failed. Please try out later."
            case entityNotFound = "Entity not found."
            case invalidChecksum = "Checksum address validation failed."
            case safeInfoNotFound = "Safe info is not found."
            case unexpectedError = "Unexpected error. We are notified and will try to fix it asap."

            /// Create a proper message from our backend internal code.
            /// - Parameter code: backend internal code of error.
            init(code: Int) {
                switch code {
                case 1:
                    self = .invalidChecksum
                case 50:
                    self = .safeInfoNotFound
                default:
                    LogService.shared.error(
                        "Unrecognised error code: \(code)",
                        error: UnexpectedError.unrecognizedErrorCode(code)
                    )
                    self = .unexpectedError
                }
            }
        }

        var errorDescription: String? {
            switch self {
            case .networkRequestFailed(_, _, _):
                return Message.networkRequestFailed.rawValue
            case .entityNotFound(_, _, _):
                return Message.entityNotFound.rawValue
            case .unprocessableEntity(_, _, let data):
                guard let data = data else {
                    LogService.shared.error(
                        "Missing data in unprocessableEntity error",
                        error: UnexpectedError.missingDataInUnprocessableEntity
                    )
                    return Message.unexpectedError.rawValue
                }
                do {
                    let details = try JSONDecoder().decode(ErrorDetails.self, from: data)
                    return Message(code: details.code).rawValue
                } catch {
                    let dataString = String(data: data, encoding: .utf8) ?? data.base64EncodedString()
                    LogService.shared.error(
                        "Could not decode error details from the data: \(dataString)",
                        error: UnexpectedError.errorDetailsDecodingFailed(dataString)
                    )
                    return Message.unexpectedError.rawValue
                }
            case .unknownError(let request, let response, let data):
                let requestStr = String(describing: request)
                let responseStr = response.map { String(describing: $0) } ?? "<no response>"
                let dataStr = data.map { String(data: $0, encoding: .utf8) ?? $0.base64EncodedString() } ?? "<no data>"
                let msg = "Unknown HTTP error. Request: \(requestStr); Response: \(responseStr); Data: \(dataStr)"
                LogService.shared.error(
                    msg,
                    error: UnexpectedError.unknownHTTPError(msg)
                )
                return Message.unexpectedError.rawValue
            }
        }

        struct ErrorDetails: Decodable {
            let code: Int
            let message: String?
        }
    }

    /// Executes request and returns server response. The call is synchronous.
    ///
    /// - Parameter request: a request to send
    /// - Returns: response
    /// - Throws:
    ///     - `HTTPClient.Error.networkRequestFailed` in case request fails
    ///     - Network errors are rethrown (URLSession errors, for example)
    @discardableResult
    func execute<T: HTTPRequest>(request: T) throws -> Data {
        logger?.debug("Preparing to send \(request)")
        let urlRequest = try self.urlRequest(from: request)
        let result = send(urlRequest)
        return try self.response(from: urlRequest, result: result)
    }

    private func urlRequest<T: HTTPRequest>(from request: T) throws -> URLRequest {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponents.path = request.urlPath
        urlComponents.query = request.query
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = request.httpMethod
        if request.httpMethod != "GET" {
            urlRequest.httpBody = request.body
            if let str = String(data: urlRequest.httpBody!, encoding: .utf8) {
                logger?.debug(str)
            }
            request.headers.forEach { header, value in
                urlRequest.setValue(value, forHTTPHeaderField: header)
            }
        }
        return urlRequest
    }

    private func send(_ request: URLRequest) -> URLDataTaskResult {
        dispatchPrecondition(condition: .notOnQueue(.main))

        var result: URLDataTaskResult!
        let semaphore = DispatchSemaphore(value: 0)
        logger?.debug("Sending request \(request)")

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            result = (data, response, error)
            semaphore.signal()
        }
        dataTask.resume()
        semaphore.wait()
        logger?.debug("Received response \(result!)")
        return result
    }

    private func response(from request: URLRequest, result: URLDataTaskResult) throws -> Data {
        if let data = result.data, let rawResponse = String(data: data, encoding: .utf8) {
            logger?.debug(rawResponse)
        }
        if let error = result.error {
            throw error
        }
        guard let httpResponse = result.response as? HTTPURLResponse else {
            throw Error.networkRequestFailed(request, result.response, result.data)
        }
        if (200...299).contains(httpResponse.statusCode) {
            return result.data ?? Data()
        } else if httpResponse.statusCode == 404 {
            throw Error.entityNotFound(request, result.response, result.data)
        } else if httpResponse.statusCode == 422 {
            throw Error.unprocessableEntity(request, result.response, result.data)
        }
        throw Error.unknownError(request, result.response, result.data)
    }
}
