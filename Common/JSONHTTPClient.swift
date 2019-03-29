//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// JSON model of a request.
public protocol JSONRequest: Encodable {

    /// GET, POST, PUT, DELETE
    var httpMethod: String { get }
    /// Path to resource, without baseURL
    var urlPath: String { get }
    /// Query parameters
    var query: String? { get }

    /// Response associated with this JSON request
    associatedtype ResponseType: Decodable

}

public extension JSONRequest {
    var query: String? { return nil }
}

public extension DateFormatter {

    /// Date formatter with format "yyyy-MM-dd'T'HH:mm:ss+00:00"
    static let networkDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss+00:00"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

}

/// Synchronous http client that sends JSON requests and receives JSON responses.
public class JSONHTTPClient {

    /// Client error
    ///
    /// - networkRequestFailed: network request failed for some reason. Provided are request, response and data values.
    public enum Error: Swift.Error {
        case networkRequestFailed(URLRequest, URLResponse?, Data?)
    }

    private typealias URLDataTaskResult = (data: Data?, response: URLResponse?, error: Swift.Error?)

    private let baseURL: URL
    private let logger: Logger?

    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter.networkDateFormatter
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }()

    /// Creates new client with baseURL and logger
    ///
    /// - Parameters:
    ///   - url: base url for creating all request urls
    ///   - logger: logger for debugging and error purposes
    public init(url: URL, logger: Logger? = nil) {
        baseURL = url
        self.logger = logger
    }

    /// Executes request and returns server response converted to ResponseType. The call is synchronous.
    ///
    /// - Parameter request: a request to send
    /// - Returns: response
    /// - Throws:
    ///     - `JSONHTTPClient.Error.networkRequestFailed` in case request fails
    ///     - JSONDecoder error in case response could not be decoded properly
    ///     - Network errors are rethrown (URLSession errors, for example)
    @discardableResult
    public func execute<T: JSONRequest>(request: T) throws -> T.ResponseType {
        logger?.debug("Preparing to send \(request)")
        let urlRequest = try self.urlRequest(from: request)
        let result = send(urlRequest)
        let response: T.ResponseType = try self.response(from: urlRequest, result: result)
        return response
    }

    private func urlRequest<T: JSONRequest>(from jsonRequest: T) throws -> URLRequest {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponents.path = jsonRequest.urlPath
        urlComponents.query = jsonRequest.query
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = jsonRequest.httpMethod
        if jsonRequest.httpMethod != "GET" {
            request.httpBody = try jsonEncoder.encode(jsonRequest)
            if let str = String(data: request.httpBody!, encoding: .utf8) {
                logger?.debug(str)
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
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

    private func response<T: Decodable>(from request: URLRequest, result: URLDataTaskResult) throws -> T {
        if let data = result.data, let rawResponse = String(data: data, encoding: .utf8) {
            logger?.debug(rawResponse)
        }
        if let error = result.error {
            throw error
        }
        guard let httpResponse = result.response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
            var data = result.data else {
                throw Error.networkRequestFailed(request, result.response, result.data)
        }
        if data.isEmpty {
            data = "{}".data(using: .utf8)!
        }
        let response: T
        do {
            response = try JSONDecoder().decode(T.self, from: data)
        } catch let error {
            logger?.error("Failed to decode response: \(error)")
            throw error
        }
        return response
    }

}
