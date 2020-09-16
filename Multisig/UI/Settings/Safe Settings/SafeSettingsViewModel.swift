//
//  SafeSettingsViewModel.swift
//  Multisig
//
//  Created by Moaaz on 5/6/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class SafeSettingsViewModel: BasicLoadableViewModel {
    var safe: Safe

    init(safe: Safe) {
        self.safe = safe
        super.init()
        reloadData()
    }

    override func reload() {
        Just(safe.address)
            .compactMap { $0 }
            .compactMap { Address($0) }
            .receive(on: DispatchQueue.global())
            .tryMap {  address -> SafeStatusRequest.Response in
                let safeInfo = try Safe.download(at: address)
                return safeInfo
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let `self` = self else { return }
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                    App.shared.snackbar.show(message: error.localizedDescription)
                }
                self.isLoading = false
                self.isRefreshing = false
            }, receiveValue: { [weak self] response in
                guard let `self` = self else { return }
                self.safe.update(from: response)
                self.errorMessage = nil
            })
            .store(in: &subscribers)
    }
}

extension Safe {
    func update(from safeInfo: SafeStatusRequest.Response) {
        // check if we need to update owners
        // always updating owners will cause an infinite loop
        let newOwners = safeInfo.owners.map { $0.address }
        if owners != newOwners {
            owners = newOwners
            App.shared.coreDataStack.saveContext()
        }

        objectWillChange.send()
        threshold = safeInfo.threshold.value
        implementation = safeInfo.implementation.address
        version = safeInfo.version
        nonce = safeInfo.nonce.value
        modules = safeInfo.modules.map { $0.address }
        fallbackHandler = safeInfo.fallbackHandler.address
    }
}
