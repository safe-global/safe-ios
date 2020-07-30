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
}
