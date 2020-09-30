//
//  EnterENSNameViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class EnterENSNameViewModel: ObservableObject {

    @Published
    var text: String = ""

    @Published
    var address: Address?

    @Published
    var isResolving: Bool?

    @Published
    var isValid: Bool?

    @Published
    var errorMessage: String = ""

    private var subscribers = Set<AnyCancellable>()

    func resolve(name: String) {
        subscribers.forEach { $0.cancel() }

        $text
            .map { [weak self] v -> String in
                guard let `self` = self else { return "" }
                self.reset()
                return v.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .tryMap { [weak self] v -> String in
                guard let `self` = self else { return "" }
                self.startResolving()
                return v
            }
            .receive(on: DispatchQueue.global())
            .tryMap { ensName -> Address in
                let address = try App.shared.ens.address(for: ensName)
                return address
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.setError(error.localizedDescription)
                }
            }, receiveValue: { [weak self] address in
                    self?.setSuccess(address)
            })
            .store(in: &subscribers)
    }

    func reset() {
        isResolving = nil
        isValid = nil
        address = nil
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

    func setSuccess(_ address: Address) {
        isResolving = false
        isValid = true
        self.address = address
    }
}
