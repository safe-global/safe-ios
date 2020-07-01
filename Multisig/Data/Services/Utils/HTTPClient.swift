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

    enum Error: LocalizedError {
        case networkRequestFailed(URLRequest, URLResponse?, Data?)
        case entityNotFound(URLRequest, URLResponse?, Data?)
        case unprocessableEntity(URLRequest, URLResponse?, Data?)
        case unknownError(URLRequest, URLResponse?, Data?)

        enum Message: String {
            case networkRequestFailed = "No internet connection."
            case entityNotFound = "Entity not found."
            case invalidSafeChecksum = "Safe address checksum is not valid."
            case unexpectedError = "Unexpected error. We are notified and will try to fix it asap."

            /// Create a proper message from our backend internal code.
            /// - Parameter code: backend internal code of error.
            init(code: Int) {
                #warning("TODO: this is a placeholder. Need to use real codes.")
                switch code {
                case 1000:
                    self = .invalidSafeChecksum
                default:
                    #warning("TODO: Crashlytics.")
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
                    #warning("TODO: Crashlytics")
                    return Message.unexpectedError.rawValue
                }
                do {
                    let details = try JSONDecoder().decode(ErrorDetails.self, from: data)
                    guard let code = details.code else {
                        #warning("TODO: Crashlytics")
                        return Message.unexpectedError.rawValue
                    }
                    return Message(code: code).rawValue
                } catch {
                    #warning("TODO: Crashlytics")
                    return Message.unexpectedError.rawValue
                }
            default:
                #warning("TODO: Crashlytics")
                return Message.unexpectedError.rawValue
            }
        }

        struct ErrorDetails: Decodable {
            let code: Int?
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
        dispatchPrecondition(condition: .onQueue(.global()))

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
