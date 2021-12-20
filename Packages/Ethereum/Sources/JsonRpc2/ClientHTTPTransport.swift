//
//  ClientHTTPTransport.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

extension JsonRpc2 {
    public struct ClientHTTPTransport: JsonRpc2ClientTransport {
        public var url: String = ""

        public init(url: String = "") {
            self.url = url
        }

        public func send(data: Data, completion: @escaping (Result<Data, Swift.Error>) -> Void) {
            guard var urlRequest = URL(string: url).map({ URLRequest.init(url: $0) }) else {
                completion(.failure(JsonRpc2.Error.invalidServerUrl))
                return
            }
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = data
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let dataTask = URLSession.shared.dataTask(with: urlRequest) { dataOrNil, _, errorOrNil in
                // From the docs:
                // If the request completes successfully, the data parameter of the completion handler block
                // contains the resource data, and the error parameter is nil.
                //
                // If the request fails, the data parameter is nil and the error parameter
                // contain information about the failure.
                if let data = dataOrNil, errorOrNil == nil {
                    completion(.success(data))
                } else if let error = errorOrNil {
                    completion(.failure(error))
                } else {
                    completion(.failure(JsonRpc2.Error.urlSessionError))
                }
            }
            dataTask.resume()
        }
    }
}
