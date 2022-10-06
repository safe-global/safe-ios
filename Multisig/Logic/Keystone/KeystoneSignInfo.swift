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
    enum KeystoneSignType: Int {
        case personalMessage = 3
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
            let signType = KeystoneSignRequest.SignType(rawValue: signType.rawValue),
            keyInfo.keyType == .keystone
        else { return nil }
        
        return KeystoneSignRequest(
            requestId: requestId,
            signData: signData,
            signType: signType,
            chainId: chainIdNumber,
            path: keyMetadata.path,
            xfp: keyMetadata.sourceFingerprint,
            address: "",
            origin: "safe ios"
        )
    }
}
