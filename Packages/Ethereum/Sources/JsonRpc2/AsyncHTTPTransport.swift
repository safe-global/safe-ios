//
//  AsyncHTTPTransport.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

extension JsonRpc2 {
    @available(iOS 15.0.0, *)
    @available(macOS 12.0.0, *)
    public struct AsyncHTTPTransport: JsonRpc2ClientAsyncTransport {
        public var url: String = ""

        public init(url: String = "") {
            self.url = url
        }

        public func send(data: Data) async throws -> Data {
            guard let url = URL(string: url) else {
                throw JsonRpc2.Error.invalidServerUrl
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = data
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            return data
        }
    }
}
