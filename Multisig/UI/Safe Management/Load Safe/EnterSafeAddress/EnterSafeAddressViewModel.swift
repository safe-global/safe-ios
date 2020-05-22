//
//  EnterSafeAddressViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class EnterSafeAddressViewModel: ObservableObject {

    enum FormError: LocalizedError {
        case safeExists

        var errorDescription: String? {
            "There is already a Safe with this address in the app. Please use another address."
        }
    }

    @Published
    var text: String = ""

    @Published
    var displayText: String = ""

    @Published
    var isAddress: Bool = false

    @Published
    var isValid: Bool?

    @Published
    var isValidating: Bool = false

    @Published
    var errorMessage: String = ""

    private var subscribers = Set<AnyCancellable>()

    func validate(address: String) {
        subscribers.forEach { $0.cancel() }

        $text
            .filter { !$0.isEmpty }
            .removeDuplicates()
            .map { v -> String in
                self.reset()
                return v.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .tryMap { text -> String in
                let address = try Address(text, true)
                return address.hex(eip55: true)
            }
            .map { v -> String in
                self.isAddress = true
                self.displayText = v

                self.isValidating = true
                return v
            }
            .flatMap { address in
                Future<String, Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            try Safe.download(at: address)
                            promise(.success(address))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .receive(on: RunLoop.main)
            .tryMap { address -> String in
                let exists = try Safe.exists(address)
                if exists  { throw FormError.safeExists }
                return address
            }
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if case HTTPClient.Error.entityNotFound(_, _, _) = error {
                        self.setError("We could not find a safe with this address.")
                    } else {
                        self.setError(error.localizedDescription)
                    }
                }
            }, receiveValue: { address in
                self.isValidating = false
                self.isValid = true
            })
            .store(in: &subscribers)
    }

    func reset() {
        isValidating = false
        isAddress = false
        isValid = nil
        errorMessage = ""
    }

    func setError(_ message: String) {
        self.isValidating = false
        self.isValid = false

        self.errorMessage = message
        self.displayText = self.text
    }
}
