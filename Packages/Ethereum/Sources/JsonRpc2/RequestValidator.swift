//
//  RequestValidator.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

extension JsonRpc2 {
    public struct RequestValidator: JsonRpc2ClientValidator {
        public init() {}
        
        public func validate(request: JsonRpc2.Request) throws {
            // jsonrpc: MUST be exactly "2.0"
            guard request.jsonrpc == "2.0" else {
                throw JsonRpc2.Error.invalidRequest.with(
                    data: .string("jsonrpc must be '2.0'. Received: '\(request.jsonrpc)'"))
            }

            // method:
            // Method names that begin with the word rpc followed by a period character (U+002E or ASCII 46)
            // are reserved for rpc-internal methods and extensions and MUST NOT be used for anything else.
            if request.method.hasPrefix("rpc.") {
                throw JsonRpc2.Error.invalidRequest.with(
                    data: .string("method must not start with reserved 'rpc.'. Received: '\(request.jsonrpc)'"))
            }

            // id:
            // The value SHOULD normally not be Null [1] and Numbers SHOULD NOT contain fractional parts
            if request.id == .null {
                throw JsonRpc2.Error.invalidRequest.with(data: .string("id should not be Null"))
            }

            if case let .double(value) = request.id, value.truncatingRemainder(dividingBy: 1) != 0 {
                throw JsonRpc2.Error.invalidRequest.with(data: .string("id should not contain fractional parts"))
            }
        }

        public func validate(response: JsonRpc2.Response?, for request: JsonRpc2.Request) throws {
            // The Server MUST NOT reply to a Notification, including those that are within a batch request.
            guard let id = request.id else {
                if response != nil {
                    throw JsonRpc2.Error.invalidResponse.with(data: .string("server must not reply with response to a notificaiton"))
                }
                return
            }

            guard let response = response else {
                throw JsonRpc2.Error.invalidResponse.with(data: .string("empty response for a request"))
            }

            // jsonrpc:
            // MUST be exactly "2.0".
            guard response.jsonrpc == "2.0" else {
                throw JsonRpc2.Error.invalidResponse.with(data: .string("jsonrpc must be '2.0'. Got '\(response.jsonrpc)'"))
            }

            // id:
            // It MUST be the same as the value of the id member in the Request Object.
            // If there was an error in detecting the id in the Request object (e.g. Parse error/Invalid Request), it MUST be Null.
            guard response.id == .null || response.id == id else {
                throw JsonRpc2.Error.invalidResponse.with(data: .string("response id '\(response.id)' not matching request id '\(id)'"))
            }

            // Either the `result` member or `error` member MUST be included, but both members MUST NOT be included.
            guard response.result == nil && response.error != nil || response.result != nil && response.error == nil else {
                throw JsonRpc2.Error.invalidResponse.with(data: .string("either 'result' or 'error' must be present but not both."))
            }
        }

        public func error(for request: JsonRpc2.Request, value: JsonRpc2.Error) -> JsonRpc2.Response? {
            // no response object should be returned to the client for notification requests (requests wihtout id)
            guard let id = request.id else { return nil }
            // otherwise, return error response
            return JsonRpc2.Response(
                jsonrpc: "2.0",
                result: nil,
                error: value,
                id: id)
        }
    }
}
