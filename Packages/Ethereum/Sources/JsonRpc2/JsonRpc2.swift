//
//  JsonRpc2.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 15.12.21.
//

import Foundation
import Json

public enum JsonRpc2 {
    public struct Request {
        public var jsonrpc: String
        public var method: String
        public var params: Params?
        public var id: Id?

        public init(jsonrpc: String, method: String, params: JsonRpc2.Params?, id: JsonRpc2.Id?) {
            self.jsonrpc = jsonrpc
            self.method = method
            self.params = params
            self.id = id
        }
    }

    public enum Params {
        case array(Json.Array)
        case object(Json.Object)
    }

    public enum Id: Hashable {
        case string(String)
        case int(Int)
        case uint(UInt)
        case double(Double)
        case null
    }

    public struct Response {
        public var jsonrpc: String
        public var result: Json.Element?
        public var error: Error?
        public var id: Id

        public init(jsonrpc: String, result: Json.Element?, error: JsonRpc2.Error?, id: JsonRpc2.Id) {
            self.jsonrpc = jsonrpc
            self.result = result
            self.error = error
            self.id = id
        }
    }

    public struct Error: Swift.Error {
        public var code: Int
        public var message: String
        public var data: Json.Element?

        public init(code: Int, message: String, data: Json.Element?) {
            self.code = code
            self.message = message
            self.data = data
        }
    }

    public struct BatchRequest {
        public var requests: [Request?]

        public init(requests: [Request?]) throws {
            // we'd like to throw error if we're empty or all are nils
            // otherwise the 'nil' are as a placeholder for some invalid request.
            let validatedRequests = requests.compactMap { $0 }
            if validatedRequests.isEmpty {
                throw Error(code: -32600, message: "Invalid Request", data: nil)
            }
            self.requests = requests
        }
    }

    public enum BatchResponse {
        case response(Response)
        case array([Response])
    }
}

// support for typed params | response results | error data:
// since all of them are codable, one can encode them and
// then decode to a typed param in order to not deal with other stuff.

// request encoding/decoding: compiler-generated
extension JsonRpc2.Request: Codable {}

extension JsonRpc2.Params: Encodable {
    public func encode(to encoder: Encoder) throws {
        // encode each associated value
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

extension JsonRpc2.Params: Decodable {
    public init(from decoder: Decoder) throws {
        // try array
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Json.Array.self) {
            self = .array(value)
        }
        // try object
        else if let value = try? container.decode(Json.Object.self) {
            self = .object(value)
        }
        // fail with error
        else {
            let error = DecodingError.typeMismatch(
                Self.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Unexpected params type",
                                      underlyingError: nil)
            )
            throw error
        }
    }
}

extension JsonRpc2.Id: Encodable {
    public func encode(to encoder: Encoder) throws {
        // encode each associated value or null
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .uint(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

extension JsonRpc2.Id: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // try int
        if let value = try? container.decode(Int.self) {
            self = .int(value)
        }
        // try uint
        else if let value = try? container.decode(UInt.self) {
            self = .uint(value)
        }
        // try double
        else if let value = try? container.decode(Double.self) {
            self = .double(value)
        }
        // try string
        else if let value = try? container.decode(String.self) {
            self = .string(value)
        }
        // try null
        else if container.decodeNil() {
            self = .null
        }
        // fail with error
        else {
            let error = DecodingError.typeMismatch(
                Self.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Unexpected id type",
                                      underlyingError: nil)
            )
            throw error
        }
    }
}

// id: comparable
// only works if both are numbers int uint will be cast to Int(clamping:) and ints will be cast to Double
// strings are compared only to strings
// nulls and other combinations return false
// otherwise they're not comparable (returns false).
extension JsonRpc2.Id: Comparable {
    public static func < (lhs: JsonRpc2.Id, rhs: JsonRpc2.Id) -> Bool {
        switch (lhs, rhs) {

        case let (.int(a), .int(b)):
            return a < b
        case let (.int(a), .uint(b)):
            return a < b
        case let (.int(a), .double(b)):
            return Double(a) < b


        case let (.uint(a), .uint(b)):
            return a < b
        case let (.uint(a), .int(b)):
            return Int(clamping: a) < b
        case let (.uint(a), .double(b)):
            return Double(a) < b

        case let (.string(a), .string(b)):
            return a < b

        case let (.double(a), .double(b)):
            return a < b
        case let (.double(a), .int(b)):
            return a < Double(b)
        case let (.double(a), .uint(b)):
            return a < Double(b)

        case (.null, .null):
            return false

        default:
            return false
        }
    }
}

// response encoding/decoding: compiler-generated
extension JsonRpc2.Response: Codable {
    enum Key: String, CodingKey {
        case jsonrpc
        case result
        case error
        case id
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        if container.contains(.result) {
            result = try container.decode(Json.Element.self, forKey: .result)
            error = nil
        } else {
            result = nil
            error = try container.decodeIfPresent(JsonRpc2.Error.self, forKey: .error)
        }
        id = try container.decode(JsonRpc2.Id.self, forKey: .id)
    }
}

// error encoding/decoding: compiler-generated
extension JsonRpc2.Error: Codable {}

extension JsonRpc2.BatchRequest: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(requests)
    }
}

extension JsonRpc2.BatchRequest: Decodable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var requests = [JsonRpc2.Request?]()
        // try decoding each request and skip the invalid requests
        if let count = container.count {
            for _ in (0..<count) {
                let request: JsonRpc2.Request?
                do {
                    request = try container.decode(JsonRpc2.Request.self)
                } catch {
                    // error decoding request, it is invalid. We put a placeholder - nil
                    request = nil
                    // we must continue, so we should decode a generic json
                    _ = try container.decode(Json.Element.self)
                }
                requests.append(request)
            }
        } else {
            requests = try container.decode([JsonRpc2.Request].self)
        }
        try self.init(requests: requests)
    }
}

extension JsonRpc2.BatchResponse: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .response(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

extension JsonRpc2.BatchResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // try array response
        if let value = try? container.decode([JsonRpc2.Response].self) {
            self = .array(value)
        }
        // try single response
        else if let value = try? container.decode(JsonRpc2.Response.self) {
            self = .response(value)
        }
        // fail with error
        else {
            let error = DecodingError.typeMismatch(
                Self.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Unexpected batch response",
                                      underlyingError: nil)
            )
            throw error
        }
    }
}

// default implementation
extension JsonRpc2.Params: EncodableConvertible, DecodableConvertible {}


// utility to create requests and responses for the same rpc call
@available(*, deprecated: 13, message: "Use JsonRpc2MethodCall or JsonRpc2MethodWithCompletion")
public protocol JsonRpc2Method {
    static var name: String { get }
    associatedtype Return
}

extension JsonRpc2Method {
    public static var name: String { String(describing: self) }
}

extension JsonRpc2Method where Self: Encodable {
    public func request(id: JsonRpc2.Id? = nil) throws -> JsonRpc2.Request {
        try JsonRpc2.Request(
            jsonrpc: "2.0",
            method: Self.name,
            params: JsonRpc2.Params(value: self),
            id: id)
    }
}

extension JsonRpc2Method where Return: Decodable {
    public func result(from element: Json.Element) throws -> Return {
        try element.convert(to: Return.self)
    }
}

public protocol JsonRpc2MethodCall {
    var methodName: String { get }
    func request(id: JsonRpc2.Id?) throws -> JsonRpc2.Request
    func handle(response: JsonRpc2.Response)
    func handle(error: Error)
}

public protocol JsonRpc2MethodWithCompletion: JsonRpc2MethodCall {
    var completion: (Result<ReturnType, Error>) -> Void { get }
    associatedtype ReturnType
    func convert(json: Json.Element) throws -> ReturnType
}

extension JsonRpc2MethodCall {
    public var methodName: String {
        String(describing: type(of: self))
    }
}

extension JsonRpc2MethodCall where Self: Encodable {
    public func request(id: JsonRpc2.Id?) throws -> JsonRpc2.Request {
        try JsonRpc2.Request(
                jsonrpc: "2.0",
                method: methodName,
                params: JsonRpc2.Params(value: self),
                id: id)
    }
}

extension JsonRpc2MethodWithCompletion where ReturnType: Decodable {
    public func handle(response: JsonRpc2.Response) {
        if let error = response.error {
            handle(error: error)
            return
        }
        guard let json = response.result else {
            return
        }
        do {
            let result = try convert(json: json)
            completion(.success(result))
        } catch {
            handle(error: error)
        }
    }

    public func convert(json: Json.Element) throws -> ReturnType {
        try json.convert(to: ReturnType.self)
    }

    public func handle(error: Error) {
        completion(.failure(error))
    }
}

extension JsonRpc2.Error {
    // JSON RPC Errors
    // |       code       |     message      |                      meaning                       |
    // | ---------------- | ---------------- | -------------------------------------------------- |
    // | -32700           | Parse error      | Invalid JSON was received by the server.           |
    // | -32600           | Invalid Request  | The JSON sent is not a valid Request object.       |
    // | -32601           | Method not found | The method does not exist or is not available.     |
    // | -32602           | Invalid params   | Invalid method parameter(s).                       |
    // | -32603           | Internal error   | Internal JSON-RPC error.                           |
    // | -32000 to -32099 | Server error     | Reserved for implementation-defined server-errors. |

    // Invalid JSON was received by the server.
    public static let parseError       = JsonRpc2.Error(code: -32700, message: "Parse error", data: nil)

    // The JSON sent is not a valid Request object.
    public static let invalidRequest   = JsonRpc2.Error(code: -32600, message: "Invalid Request", data: nil)

    // The method does not exist or is not available.
    public static let methodNotFound   = JsonRpc2.Error(code: -32601, message: "Method not found", data: nil)

    // Invalid method parameter(s).
    public static let invalidParams    = JsonRpc2.Error(code: -32602, message: "Invalid params", data: nil)

    // Internal JSON-RPC error.
    public static let internalError    = JsonRpc2.Error(code: -32603, message: "Internal error", data: nil)

    // Reserved for implementation-defined server-errors. Start of the range.
    public static let serverError00    = JsonRpc2.Error(code: -32000, message: "Server error", data: nil)

    // Reserved for implementation-defined server-errors. End of the range.
    public static let serverError99    = JsonRpc2.Error(code: -32099, message: "Server error", data: nil)
}

extension JsonRpc2.Error {
    public func with(error: Swift.Error) -> JsonRpc2.Error {
        with(data: Json.NSError(error as NSError).toJson())
    }

    public func with(data: Json.Element) -> JsonRpc2.Error {
        var newValue = self
        newValue.data = data
        return newValue
    }
}

extension JsonRpc2.Error: LocalizedError {
    public var errorDescription: String? {
        var result = "Error \(code): \(message)"
        if let json = data {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            if let data = try? encoder.encode(json), let string = String(data: data, encoding: .utf8) {
                result += "\nData: \(string)"
            }
        }
        return result
    }
}
