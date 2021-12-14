//
//  JsonRpc2.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Namespace for the types defined by the JSON-RPC 2.0 specification
///
/// See more: https://www.jsonrpc.org/specification
enum JsonRpc2 {
    /// A rpc call is represented by sending a Request object to a Server
    struct Request<Params: Codable>: Codable {
        /// A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
        var jsonrpc: String

        /// A String containing the name of the method to be invoked. Method names that begin with the word rpc followed by a period character (U+002E or ASCII 46) are reserved for rpc-internal methods and extensions and MUST NOT be used for anything else.
        var method: String

        /// A Structured value that holds the parameter values to be used during the invocation of the method. This member MAY be omitted.
        ///
        /// Example of the named params with Codable:
        /// ```
        /// struct MyNamedParams: Codable {
        ///     var param1: String
        ///     var param2: Int
        /// }
        /// ```
        ///
        /// Example of the positional params (array of different types) with Codable:
        /// ```
        /// struct MyPositionalParams: Codable {
        ///     var param1: String
        ///     var param2: Int
        ///
        ///     init(from decoder: Decoder) throws {
        ///         var container = try decoder.unkeyedContainer()
        ///         param1 = try container.decode(String.self)
        ///         param2 = try container.decode(Int.self)
        ///     }
        ///
        ///     func encode(to encoder: Encoder) throws {
        ///         var container = encoder.unkeyedContainer()
        ///         try container.encode(param1)
        ///         try container.encode(param2)
        ///     }
        /// }
        /// ```
        var params: Params?

        /// An identifier established by the Client that MUST contain a String, Number, or NULL value if included. If it is not included it is assumed to be a notification. The value SHOULD normally not be Null [1] and Numbers SHOULD NOT contain fractional parts
        /// The Server MUST reply with the same value in the Response object if included. This member is used to correlate the context between the two objects.
        var id: Id?
    }

    struct EmptyParams: Codable {
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode([String]())
        }
    }

    /// Request identifier, it is a String, Number (integer or fractional), or NULL.
    enum Id: Codable {
        case string(String)
        case int(Int)
        case double(Double)
        case null

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = (try? container.decode(String.self)) {
                self = .string(string)
            } else if let int = (try? container.decode(Int.self)) {
                self = .int(int)
            } else if let double = (try? container.decode(Double.self)) {
                self = .double(double)
            } else if container.decodeNil() {
                self = .null
            } else {
                throw DecodingError.typeMismatch(
                    Id.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unexpected Id type in the json rpc object")
                )
            }
        }
    }

    /// When a rpc call is made, the Server MUST reply with a Response, except for in the case of Notifications. The Response is expressed as a single JSON Object
    struct Response<Success: Codable, ErrorData: Codable>: Codable {
        /// A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0"
        var jsonrpc: String

        /// Represents 2 mutually exclusive fields from the spec: result and error.
        ///
        /// `result` is present on success:
        /// This member is REQUIRED on success.
        /// This member MUST NOT exist if there was an error invoking the method.
        /// The value of this member is determined by the method invoked on the Server.
        ///
        /// `error` is present on failure:
        /// This member is REQUIRED on error.
        /// This member MUST NOT exist if there was no error triggered during invocation.
        /// The value for this member MUST be an Object as defined in section 5.1.
        var result: Result<Success, Error<ErrorData>>

        /// This member is REQUIRED.
        /// It MUST be the same as the value of the id member in the Request Object.
        /// If there was an error in detecting the id in the Request object (e.g. Parse error/Invalid Request), it MUST be Null.
        var id: Id
    }

    /// When a rpc call encounters an error, the Response Object MUST contain the error member with a value that is a Object
    struct Error<ErrorData: Codable>: Swift.Error, Codable {
        ///  A Number that indicates the error type that occurred.
        ///  This MUST be an integer.
        var code: Int

        /// A String providing a short description of the error.
        /// The message SHOULD be limited to a concise single sentence.
        var message: String

        /// A Primitive or Structured value that contains additional information about the error.
        /// This may be omitted.
        /// The value of this member is defined by the Server (e.g. detailed error information, nested errors etc.).
        var data: ErrorData?
    }
}

extension JsonRpc2.Response {
    enum Keys: String, CodingKey {
        case jsonrpc, result, error, id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        id = try container.decode(JsonRpc2.Id.self, forKey: .id)

        if let result = try container.decodeIfPresent(Success.self, forKey: .result) {
            self.result = .success(result)
        } else if let error = try container.decodeIfPresent(JsonRpc2.Error<ErrorData>.self, forKey: .error) {
            self.result = .failure(error)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expecting either `result` or `error` field present in the response, but none found.")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(id, forKey: .id)

        switch result {
        case .success(let result):
            try container.encode(result, forKey: .result)
        case .failure(let error):
            try container.encode(error, forKey: .error)
        }
    }
}
