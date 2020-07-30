//
//  HTTPClientUnexpectedError.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

enum HTTPClientUnexpectedError: LoggableError {
    case unrecognizedErrorCode(Int)
    case missingDataInUnprocessableEntity
    case errorDetailsDecodingFailed(String)
    case unknownHTTPError(String)
}
