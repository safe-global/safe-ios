//
//  JsonRpc2ClientTransport.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

// Responsible for sending a json data to the Server and receiving response (if any)
public protocol JsonRpc2ClientTransport {
    @discardableResult
    func send(data: Data, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask?
}

@available(iOS 15.0.0, *)
@available(macOS 12.0.0, *)
public protocol JsonRpc2ClientAsyncTransport {
    func send(data: Data) async throws -> Data
}
