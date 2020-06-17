//
//  TrnasactionConfirmation.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionConfirmation: Decodable, Hashable {
    let owner: AddressString
    let submissionDate: Date
    let transactionHash: DataString?
    let data: DataString?
    let signature: DataString?
    let signatureType: SignatureType?
}

enum SignatureType: String, Decodable {
    case contractSignature = "CONTRACT_SIGNATURE"
    case approvedHash = "APPROVED_HASH"
    case eoa = "EOA"
    case ethSignature = "ETH_SIGN"
}
