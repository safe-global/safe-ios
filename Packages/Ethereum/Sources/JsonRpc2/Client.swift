//
//  Client.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 15.12.21.
//

import Foundation
import Json

extension JsonRpc2 {
    // The Client is defined as the origin of Request objects and the handler of Response objects.
    public struct Client {
        public var transport: JsonRpc2ClientTransport
        public var serializer: JsonRpc2ClientSerializer

        public init(transport: JsonRpc2ClientTransport, serializer: JsonRpc2ClientSerializer) {
            self.transport = transport
            self.serializer = serializer
        }

        @discardableResult
        public func send(request: JsonRpc2.Request, completion: @escaping (JsonRpc2.Response?) -> Void) -> URLSessionTask? {
            send(request: request, validator: JsonRpc2.RequestValidator(), completion: completion)
        }

        @discardableResult
        public func send(request: JsonRpc2.BatchRequest, completion: @escaping (JsonRpc2.BatchResponse?) -> Void) -> URLSessionTask? {
            send(request: request, validator: JsonRpc2.BatchRequestValidator(JsonRpc2.RequestValidator()), completion: completion)
        }

        // Generic send allows to have both batch and single request types to use the  same algorithm.
        @discardableResult
        public func send<Request, Response, Validator>(
            request: Request,
            validator: Validator,
            completion: @escaping (Response?) -> Void
        ) -> URLSessionTask?
        where Validator: JsonRpc2ClientValidator,
              Validator.Request == Request,
              Validator.Response == Response,
              Request: Encodable,
              Response: Decodable
        {
            // validate request
            do {
                try validator.validate(request: request)
            } catch let jsonRpc2Error as JsonRpc2.Error {
                completion(validator.error(for: request, value: jsonRpc2Error))
            } catch let programmersError {
                fatalError("Request validation fails with unexpected error: \(programmersError)")
            }

            // convert request to json
            let jsonRequest: Data
            do {
                jsonRequest = try serializer.toJson(value: request)
            } catch let swiftEncodingError {
                completion(validator.error(for: request, value: .parseError.with(error: swiftEncodingError)))
                return nil
            }

            // send request
            let task = transport.send(data: jsonRequest) { result in
                // handle response
                switch result {
                case .success(let jsonResponse):

                    // empty response
                    if jsonResponse.isEmpty {

                        // validate empty response
                        do {
                            try validator.validate(response: nil, for: request)
                        } catch let jsonRpc2Error as JsonRpc2.Error {
                            completion(validator.error(for: request, value: jsonRpc2Error))
                            return
                        } catch let programmerError {
                            fatalError("Empty response validation fails with unexpected error: \(programmerError)")
                        }
                        // else valid response
                        completion(nil)
                        return
                    }
                    // else response is not empty.

                    // convert response from json
                    let response: Response
                    do {
                        response = try serializer.fromJson(data: jsonResponse)
                    } catch let swiftDecodingError {
                        let jsonString = String(data: jsonResponse, encoding: .utf8) ?? "<n/a>"
                        let data = Json.Element.object(Json.Object(members: [
                            "response": Json.Element.string(jsonString),
                            "swiftError": Json.NSError(swiftDecodingError as NSError).toJson()
                        ]))
                        completion(validator.error(for: request, value: .parseResponseError.with(data: data)))
                        return
                    }

                    // validate response
                    do {
                        try validator.validate(response: response, for: request)
                    } catch let jsonRpc2Error as JsonRpc2.Error {
                        completion(validator.error(for: request, value: jsonRpc2Error))
                        return
                    } catch let programmerError {
                        fatalError("Response validation fails with unexpected error: \(programmerError)")
                    }
                    // else handle valid response
                    completion(response)

                case .failure(let lowLevelSendingError):
                    completion(validator.error(for: request, value: .requestFailed.with(error: lowLevelSendingError)))
                }
            }
            task?.resume()
            return task
        }

        // MARK: - Convenience methods
        public func call(_ method: JsonRpc2MethodCall) -> URLSessionTask? {
            let request: JsonRpc2.Request
            do {
                request = try method.request(id: .int(0))
            } catch {
                method.handle(error: error)
                return nil
            }
            return send(request: request) { response in
                if let response = response {
                    method.handle(response: response)
                }
            }
        }

        public func call(_ methods: [JsonRpc2MethodCall], completion: @escaping () -> Void = {}) -> URLSessionTask? {
            let batch: JsonRpc2.BatchRequest
            do {
                let requests = try methods.enumerated().map { index, method in
                    try method.request(id: .int(index))
                }
                batch = try JsonRpc2.BatchRequest(requests: requests)
            } catch {
                methods.forEach { method in method.handle(error: error) }
                completion()
                return nil
            }
            return send(request: batch) { response in

                guard let response = response else {
                    // else all requests are notifications: not possible because we assigned ids to them.
                    return
                }
                switch response {
                case .response(let singleResponse):
                    guard let error = singleResponse.error else {
                        // must be error, other options not possible here according to JsonRpc2
                        return
                    }
                    methods.forEach { method in method.handle(error: error) }
                    completion()

                case .array(let array):
                    // we should match array of responses by the method ids
                    methods.enumerated().forEach { id, method in
                        guard let response = array.first(where: { response in response.id == .int(id) }) else {
                            return
                        }
                        method.handle(response: response)
                    }
                    completion()
                }
            }
        }
    }
}
