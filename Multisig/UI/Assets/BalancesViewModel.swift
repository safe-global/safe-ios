//
//  AssetsViewModel.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class BalancesViewModel: LoadableViewModel {
    @Published var balances = [TokenBalance]()
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private var subscribers = Set<AnyCancellable>()

    private let safe: Safe

    init(safe: Safe) {
        self.safe = safe
        reloadData()
    }

    func reloadData() {
        isLoading = true
        Just(safe.address!)
            .compactMap { Address($0) }
            .setFailureType(to: Error.self)
            .flatMap { address in
                Future<[TokenBalance], Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            let balancesResponse = try App.shared.safeTransactionService.safeBalances(at: address)
                            let tokenBalances = balancesResponse.map { TokenBalance($0) }
                            promise(.success(tokenBalances))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }, receiveValue:{ tokenBalances in
                self.balances = tokenBalances
            })
            .store(in: &subscribers)
    }
}
