//
//  InfuraError.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

// Infura server errors
// |  CODE  |            MESSAGE             |                    MEANING                    |   CATEGORY   |
// | ------ | ------------------------------ | --------------------------------------------- | ------------ |
// | -32000 | Invalid input                  | Missing or invalid parameters                 | non-standard |
// | -32001 | Resource not found             | Requested resource not found                  | non-standard |
// | -32002 | Resource unavailable           | Requested resource not available              | non-standard |
// | -32003 | Transaction rejected           | Transaction creation failed                   | non-standard |
// | -32004 | Method not supported           | Method is not implemented                     | non-standard |
// | -32005 | Limit exceeded                 | Request exceeds defined limit                 | non-standard |
// | -32006 | JSON-RPC version not supported | Version of JSON-RPC protocol is not supported | non-standard |
