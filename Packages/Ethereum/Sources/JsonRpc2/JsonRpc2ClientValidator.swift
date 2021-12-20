//
//  JsonRpc2ClientValidator.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

// Makes possible to reuse the same client implementation logic for both batch and single rpc requests
public protocol JsonRpc2ClientValidator {
    associatedtype Request
    associatedtype Response
    func validate(request: Request) throws
    func validate(response: Response?, for request: Request) throws
    func error(for request: Request, value: JsonRpc2.Error) -> Response?
}
