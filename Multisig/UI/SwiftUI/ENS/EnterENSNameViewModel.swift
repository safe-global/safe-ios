//
//  EnterENSNameViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine
import UnstoppableDomainsResolution

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

    init() {
        $text
            .map { [weak self] v -> String in
                guard let `self` = self else { return "" }
                self.reset()
                return v.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()

            // flatMap allows to run this pipeline multiple times by
            // transforming every text value into a new publisher that
            // loads the ENS for that text value.
            .flatMap { input in
                Just(input)
                    .tryMap { [weak self] v -> String in
                        guard let `self` = self else { return "" }
                        self.startResolving()
                        return v
                    }
                    .receive(on: DispatchQueue.global())
                    .tryMap { ensName -> Result<Address, Error> in
                        let address = try App.shared.blockchainDomainManager.resolveEnsDomain(domain: ensName)
                        return .success(address)
                    }
                    .receive(on: RunLoop.main)
                    .catch {
                        Just(.failure($0))
                    }
            }
            .sink { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let address):
                    self.setSuccess(address)
                case .failure(let error):
                    self.setError(error.localizedDescription)
                }
            }
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
