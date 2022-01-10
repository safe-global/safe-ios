//
//  BatchRequestValidator.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

extension JsonRpc2 {
    public struct BatchRequestValidator<V>: JsonRpc2ClientValidator where V: JsonRpc2ClientValidator, V.Request == JsonRpc2.Request, V.Response == JsonRpc2.Response {
        public let singleRequesValidator: V

        public init(_ validator: V) {
            singleRequesValidator = validator
        }

        public func validate(request batchRequest: JsonRpc2.BatchRequest) throws {
            // there must be at least one value in the batch for it to be valid
            if batchRequest.requests.isEmpty {
                throw JsonRpc2.Error.invalidRequest.with(data: .string("batch must have at least one request"))
            }

            for requestOrNil in batchRequest.requests {
                // batch may have 'nil' inside in case it was decoded from a JSON that was invalid batch
                if let request = requestOrNil {
                    try singleRequesValidator.validate(request: request)
                } else {
                    throw JsonRpc2.Error.invalidRequest.with(data: .string("all requests must be valid objects"))
                }
            }
        }

        // requires
        // batch reqeust without null requests
        // each request is valid request per client-side validation
        public func validate(response batchResponse: JsonRpc2.BatchResponse?, for request: JsonRpc2.BatchRequest) throws {
            let batchRequests = request.requests.compactMap { $0 }

            // A Response object SHOULD exist for each Request object, except that there SHOULD NOT be any Response objects for notifications.
            // If there are no Response objects contained within the Response array as it is to be sent to the client, the server MUST NOT return an empty Array and should return nothing at all.

            // corollary: if we send batch with all notifications then the batch response must be nil.
            let isAllNotifications = batchRequests.allSatisfy { $0.id == nil }
            if isAllNotifications && batchResponse != nil {
                throw JsonRpc2.Error.invalidResponse.with(data: .string("server must not return response for batch with all notifications"))
            }

            // else we must have some response
            guard let batchResponse = batchResponse else {
                throw JsonRpc2.Error.invalidResponse.with(data: .string("expected server response but got nothing"))
            }

            switch batchResponse {
            case .response(let singleResponse):
                // If the batch rpc call itself fails to be recognized as an valid JSON or as an Array with at least one value, the response from the Server MUST be a single Response object.
                //
                // NOTE: converse is not true, it is possible to get single response even for a valid batch. But this
                // behavior is undefined in the spec, and we treat it as error. (null id)
                //
                // We create a fake request for validation because it's undefined which request we would validate against.
                let fakeRequest = JsonRpc2.Request(jsonrpc: "2.0", method: "", params: nil, id: .null)
                try singleRequesValidator.validate(response: singleResponse, for: fakeRequest)
            case .array(let responses):
                // A Response object SHOULD exist for each Request object, except that there SHOULD NOT be any Response objects for notifications.
                // The Client SHOULD match contexts between the set of Request objects and the resulting set of Response objects based on the id member within each Object.
                // The Response objects being returned from a batch call MAY be returned in any order within the Array.

                let responsesById = Dictionary(uniqueKeysWithValues: responses.map { ($0.id, $0) })

                for request in batchRequests {
                    // skip notifications
                    guard let requestId = request.id else { continue }

                    guard let response = responsesById[requestId] else {
                        throw JsonRpc2.Error.invalidResponse.with(data: .string("response not found for request id '\(requestId)'"))
                    }

                    try singleRequesValidator.validate(response: response, for: request)
                }
            }
        }

        public func error(for request: JsonRpc2.BatchRequest, value: JsonRpc2.Error) -> JsonRpc2.BatchResponse? {
            JsonRpc2.BatchResponse.response(JsonRpc2.Response(
                jsonrpc: "2.0",
                result: nil,
                error: value,
                id: .null))
        }
    }
}
