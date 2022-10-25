//
//  KeystoneSignRequest+Transaction.swift
//  Multisig
//
//  Created by Zhiying Fan on 5/9/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import URRegistry

struct KeystoneSignInfo {
    enum KeystoneSignType {
        case transaction
        case personalMessage
        case typedTransaction
    }
    
    var signData: String
    var chain: Chain?
    var keyInfo: KeyInfo
    var signType: KeystoneSignType
}

extension KeystoneSignInfo {
    var signRequest: KeystoneSignRequest? {
        guard
            let requestId = UUID().uuidString.data(using: .utf8)?.toHexString(),
            let chainId = chain?.id,
            let chainIdNumber = UInt32(chainId),
            let metadata = keyInfo.metadata,
            let keyMetadata = KeyInfo.KeystoneKeyMetadata.from(data: metadata),
            keyInfo.keyType == .keystone
        else { return nil }
        
        let signRequestType: KeystoneSignRequest.SignType = {
            switch signType {
            case .transaction: return .transaction
            case .personalMessage: return .personalMessage
            case .typedTransaction: return .typedTransaction
            }
        }()
        
        return KeystoneSignRequest(
            requestId: requestId,
            signData: signData,
            signType: signRequestType,
            chainId: chainIdNumber,
            path: keyMetadata.path,
            xfp: keyMetadata.sourceFingerprint,
            address: "",
            origin: "safe ios"
        )
    }
}
