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
    /// URL that overrides the urlPath and query
    var url: URL? { get }

    /// Response associated with this JSON request
    associatedtype ResponseType: Decodable

}

public extension JSONRequest {
    var query: String? { return nil }
    var url: URL? { return nil }
    var urlPath: String { "/" }
    var httpMethod: String { "GET" }
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

    private let logger: Logger?
    private let client: HTTPClient

    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter.networkDateFormatter
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }()

    public lazy var jsonDecoder: JSONDecoder = {
        JSONDecoder()
    }()

    private struct Request: HTTPRequest {
        var httpMethod: String
        var urlPath: String
        var query: String?
        var body: Data?
        var headers: [String: String]
        var url: URL?
    }

    /// Creates new client with baseURL and logger
    ///
    /// - Parameters:
    ///   - url: base url for creating all request urls
    ///   - logger: logger for debugging and error purposes
    public init(url: URL, logger: Logger? = nil) {
        client = HTTPClient(url: url, logger: logger)
        self.logger = logger
    }

    /// Executes request and returns server response converted to ResponseType. The call is synchronous.
    ///
    /// - Parameter request: a request to send
    /// - Returns: response
    /// - Throws:
    ///     - `HTTPClient.Error.networkRequestFailed` in case request fails
    ///     - JSONDecoder error in case response could not be decoded properly
    ///     - Network errors are rethrown (URLSession errors, for example)
    @discardableResult
    public func execute<T: JSONRequest>(request jsonRequest: T) throws -> T.ResponseType {
        let request = try self.request(from: jsonRequest)
        let data = try client.execute(request: request)
        return try response(from: data)
    }

    public func asyncExecute<T: JSONRequest>(request jsonRequest: T, completion: @escaping (Result<T.ResponseType, Error>) -> Void) -> URLSessionTask? {
        // note: vertical spacing for better readability
        do {
            let request = try self.request(from: jsonRequest)

            let task = client.asyncExecute(request: request) { [weak self] result in
                guard let `self` = self else { return }

                switch result {

                case .success(let data):
                    do {
                        let output: T.ResponseType = try self.response(from: data)
                        completion(.success(output))
                    } catch {
                        completion(.failure(error))
                    }

                case .failure(let error):
                    completion(.failure(error))

                }
            }
            return task
        } catch {
            completion(.failure(error))
            return nil
        }
    }

    private func request<T: JSONRequest>(from request: T) throws -> Request {
        let requestData = request.httpMethod != "GET" ? (try jsonEncoder.encode(request)) : nil
        let requestHeaders = request.httpMethod != "GET" ? ["Content-Type": "application/json"] : [:]
        let httpRequest = Request(httpMethod: request.httpMethod,
                                  urlPath: request.urlPath,
                                  query: request.query,
                                  body: requestData,
                                  headers: requestHeaders,
                                  url: request.url)
        return httpRequest
    }

    private func response<T: Decodable>(from data: Data) throws -> T {
        var json = data
        if json.isEmpty {
            json = "{}".data(using: .utf8)!
        }
        let response: T
        do {
            response = try jsonDecoder.decode(T.self, from: json)
        } catch {
            logger?.error("Failed to decode response: \(error)")
            throw error
        }
        return response
    }

}
