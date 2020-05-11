//
//  SafeSettingsViewModel.swift
//  Multisig
//
//  Created by Moaaz on 5/6/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class SafeSettingsViewModel: ObservableObject {
    
    @Published
    var isLoading: Bool = true

    @Published
    var errorMessage: String? = nil

    @Published
    var safe: Safe

    private var subscribers = Set<AnyCancellable>()

    init(safe: Safe) {
        isLoading = true
        self.safe = safe
        // assuming that if address exists, it is a valid address
        // which we validated before.
        Just(safe.address)
            .compactMap { $0 }
            .receive(on: DispatchQueue.global())
            .tryMap { address -> SafeStatusRequest.Response? in
                try Safe.download(at: address)
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("error: \(error)")
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }, receiveValue: { response in
                safe.safeInfo = response
            })
            .store(in: &subscribers)
    }
    
}

extension Safe {

    var safeInfo: SafeStatusRequest.Response? {
        get { nil }
        set {
            threshold = newValue?.threshold
            owners = newValue?.owners
            masterCopy = newValue?.masterCopy
            version = newValue?.version
            nonce = newValue?.nonce
            modules = newValue?.modules
            fallbackHandler = newValue?.fallbackHandler
        }
    }

}
