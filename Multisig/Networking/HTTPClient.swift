//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol HTTPRequest {

    var httpMethod: String { get }
    var urlPath: String { get }
    var query: String? { get }
    var body: Data? { get }
    var headers: [String: String] { get }

}

public extension HTTPRequest {

    var query: String? { return nil }
    var body: Data? { return nil }
    var headers: [String: String] { return [:] }

}

/// Synchronous http client
public class HTTPClient {

    /// Client error
    ///
    /// - networkRequestFailed: network request failed for some reason. Provided are request, response and data values.
    public enum Error: Swift.Error {
        case networkRequestFailed(URLRequest, URLResponse?, Data?)
    }

    private typealias URLDataTaskResult = (data: Data?, response: URLResponse?, error: Swift.Error?)

    private let baseURL: URL
    private let logger: Logger?

    /// Creates new client with baseURL and logger
    ///
    /// - Parameters:
    ///   - url: base url for creating all request urls
    ///   - logger: logger for debugging and error purposes
    public init(url: URL, logger: Logger? = nil) {
        baseURL = url
        self.logger = logger
    }

    /// Executes request and returns server response. The call is synchronous.
    ///
    /// - Parameter request: a request to send
    /// - Returns: response
    /// - Throws:
    ///     - `HTTPClient.Error.networkRequestFailed` in case request fails
    ///     - Network errors are rethrown (URLSession errors, for example)
    @discardableResult
    public func execute<T: HTTPRequest>(request: T) throws -> Data {
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
        guard let httpResponse = result.response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
            let data = result.data else {
                throw Error.networkRequestFailed(request, result.response, result.data)
        }
        return data
    }

}
