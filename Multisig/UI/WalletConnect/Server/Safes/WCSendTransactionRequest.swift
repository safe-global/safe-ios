//
//  WCSendTransactionRequest.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 29.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import SafeWeb3

// https://docs.walletconnect.org/json-rpc-api-methods/ethereum#eth_sendtransaction
struct WCSendTransactionRequest: Decodable {
    let from: AddressString
    let to: AddressString?
    let gas: UInt256String?
    let gasPrice: UInt256String?
    let value: UInt256String?
    let data: DataString
    let nonce: UInt256String?
}
