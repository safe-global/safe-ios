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
    init?(transaction: Transaction, keyInfo: KeyInfo) {
        guard
            let requestId = UUID().uuidString.data(using: .utf8)?.toHexString(),
            let signData = transaction.data?.data.toHexString(),
            let chainId = transaction.chainId,
            let chainIdNumber = UInt32(chainId),
            let metadata = keyInfo.metadata,
            let keyMetadata = KeyInfo.KeystoneKeyMetadata.from(data: metadata)
        else { return nil }

        self.init(
            requestId: requestId,
            signData: signData,
            signType: .typedTransaction,
            chainId: chainIdNumber,
            path: keyMetadata.path,
            xfp: keyMetadata.sourceFingerprint,
            address: transaction.to.address.data.toHexString(),
            origin: "gnosis safe ios"
        )
    }
}
