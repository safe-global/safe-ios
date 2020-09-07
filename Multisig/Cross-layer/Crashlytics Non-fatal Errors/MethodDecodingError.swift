//
//  MethodDecodingError.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

enum MethodDecodingError: LoggableError {
    case unexpectedMethod(String)

    var domain: String { "MethodDecodingError" }
    var code: Int { -1 }
}
