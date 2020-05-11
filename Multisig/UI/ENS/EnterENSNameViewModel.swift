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
            .map { v -> String in
                self.reset()
                return v.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .tryMap { v -> String in
                self.startResolving()
                return v
            }
            .flatMap { ensName in
                Future { promise in
                    DispatchQueue.global().async {
                        do {
                            let address = try App.shared.ens.address(for: ensName)
                            promise(.success(address))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
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
