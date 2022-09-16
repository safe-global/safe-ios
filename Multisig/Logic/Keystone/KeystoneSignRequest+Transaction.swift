//
//  KeystoneSignRequest+Transaction.swift
//  Multisig
//
//  Created by Zhiying Fan on 5/9/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import URRegistry

extension KeystoneSignRequest {
    init?(signData: HexString, chainId: String?, keyInfo: KeyInfo, signType: SignType) {
        guard
            let requestId = UUID().uuidString.data(using: .utf8)?.toHexString(),
            let chainId = chainId,
            let chainIdNumber = UInt32(chainId),
            let metadata = keyInfo.metadata,
            let keyMetadata = KeyInfo.KeystoneKeyMetadata.from(data: metadata),
            keyInfo.keyType == .keystone
        else { return nil }
        
        self.init(
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
