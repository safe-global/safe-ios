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
    var isResolving: Bool?

    @Published
    var isValid: Bool?

    @Published
    var errorMessage: String = ""

    @Published
    var address: String = ""
    
    @Published
    var info: SafeStatusRequest.Response?
    
    private var subscribers = Set<AnyCancellable>()

    func resolve() {
        subscribers.forEach { $0.cancel() }

        $address
            .map { v -> String in
                self.reset()
                self.startResolving()
                return v
            }
            .receive(on: DispatchQueue.global())
            .tryMap(Safe.download(at: ))
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.setError(error.localizedDescription)
                }
            }, receiveValue: setSuccess(_:))
            .store(in: &subscribers)
    }

    func reset() {
        isResolving = nil
        isValid = nil
        info = nil
        errorMessage = ""
    }

    func startResolving() {
        isResolving = true
    }

    func setError(_ message: String) {
        isResolving = false
        isValid = false
        errorMessage = message
    }

    func setSuccess(_ info: SafeStatusRequest.Response?) {
        isResolving = false
        isValid = true
        self.info = info
    }
}
