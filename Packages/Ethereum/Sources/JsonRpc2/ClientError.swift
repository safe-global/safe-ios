//
//  ClientError.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

// Client errors
extension JsonRpc2.Error {
    // |  code  |       message        |                      meaning                      |
    // | ------ | -------------------- | ------------------------------------------------- |
    // | -33000 | Parse Response error | Invalid JSON Response was received by the client. |
    // | -33001 | Request failed       | Request to the server failed.                     |
    // | -33002 | Invalid server url   | Server URL string is invalid.                     |
    // | -33003 | URLSession error     | Unexpected response parameters from URL Session.  |
    // | -33004 | Invalid Response     | Invalid Response received by the client.          |

    // Invalid JSON Response was received by the client.
    public static let parseResponseError = JsonRpc2.Error(code: -33000, message: "Parse Response error", data: nil)

    // Request to the server failed.
    public static let requestFailed = JsonRpc2.Error(code: -33001, message: "Request failed", data: nil)

    // Server URL string is invalid.
    public static let invalidServerUrl = JsonRpc2.Error(code: -33002, message: "Invlaid server url", data: nil)

    // Unexpected response parameters from URL Session.
    public static let urlSessionError = JsonRpc2.Error(code: -33003, message: "URLSession error", data: nil)

    // Invalid Response received by the client.
    public static let invalidResponse = JsonRpc2.Error(code: -33004, message: "Invalid Response", data: nil)
}
