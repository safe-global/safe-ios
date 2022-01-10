//
//  AsyncClient.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

extension JsonRpc2 {
    @available(iOS 15.0.0, *)
    @available(macOS 12.0.0, *)
    public struct AsyncClient {
        public var transport: JsonRpc2ClientAsyncTransport
        public var serializer: JsonRpc2ClientSerializer

        public init(transport: JsonRpc2ClientAsyncTransport, serializer: JsonRpc2ClientSerializer) {
            self.transport = transport
            self.serializer = serializer
        }

        public func send(request: JsonRpc2.Request) async throws -> JsonRpc2.Response? {
            try await send(request: request, validator: JsonRpc2.RequestValidator())
        }

        public func send(request: JsonRpc2.BatchRequest) async throws -> JsonRpc2.BatchResponse? {
            try await send(request: request, validator: JsonRpc2.BatchRequestValidator(JsonRpc2.RequestValidator()))
        }

        public func send<Request, Response, Validator>(
            request: Request,
            validator: Validator
        )
        async throws -> Response?
        where Validator: JsonRpc2ClientValidator,
              Validator.Request == Request,
              Validator.Response == Response,
              Request: Encodable,
              Response: Decodable
        {
            try validator.validate(request: request)
            let jsonRequest: Data = try serializer.toJson(value: request)

            let jsonResponse: Data = try await transport.send(data: jsonRequest)

            if jsonResponse.isEmpty {
                try validator.validate(response: nil, for: request)
                return nil
            }
            // else response is not empty.
            let response: Response = try serializer.fromJson(data: jsonResponse)
            try validator.validate(response: response, for: request)
            return response
        }
    }
}
