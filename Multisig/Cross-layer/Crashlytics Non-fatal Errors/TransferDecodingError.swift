//
//  TransferDecodingError.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

enum TransferDeocdingError: LoggableError {
    case transferWithoutTokenAddress(String)
    case transferClassificationFailed(String)
    case transferWithInvalidTokenAndInfoType(String)
    case transferWithInvalidNonEtherType(String)

    var domain: String { "TransferDeocdingError" }
    var code: Int {
        switch self {
        case .transferWithoutTokenAddress: return -1
        case .transferClassificationFailed: return -2
        case .transferWithInvalidTokenAndInfoType: return -3
        case .transferWithInvalidNonEtherType: return -4
        }
    }
}
