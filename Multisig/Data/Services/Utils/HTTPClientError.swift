//
//  HTTPClientErrors.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

fileprivate let errorDomain = "HTTPClientError"

enum HTTPClientError {
    static func error(_ request: URLRequest, _ response: URLResponse?, _ data: Data?, _ error: Error?) -> Error {
        // system errors
        if let error = error {
            return GSError.detailedError(from: error)
        }

        // backend errors
        return GSError.detailedError(from: response as! HTTPURLResponse, data: data)
    }
}

protocol RequestFailure: CustomStringConvertible {
    var requestURL: URL? { get }
}

extension RequestFailure {
    var description: String {
        "[\(String(describing: type(of: self)))]: Request failed: \(requestURL?.absoluteString ?? "<no url>")"
    }
}
