//
//  LoadingSafeSettingsViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class LoadingSafeSettingsViewModel: NetworkContentViewModel {
    @Published
    var safe: Safe?

    func reload() {
        super.reload {  safe -> (SafeStatusRequest.Response, Safe) in
            guard let addressString = safe.address else {
                throw "Error: safe does not have address. Please reload."
            }
            let address = try Address(from: addressString)
            let safeInfo = try Safe.download(at: address)
            return (safeInfo, safe)
        } receive: { [weak self] (response, safe) in
            guard let `self` = self else { return }
            safe.update(from: response)
            self.safe = safe
        }
    }
}

extension Safe {
    func update(from safeInfo: SafeStatusRequest.Response) {
        objectWillChange.send()
        threshold = safeInfo.threshold.value
        owners = safeInfo.owners.map { $0.address }
        implementation = safeInfo.implementation.address
        version = safeInfo.version
        nonce = safeInfo.nonce.value
        modules = safeInfo.modules.map { $0.address }
        fallbackHandler = safeInfo.fallbackHandler.address
    }
}
