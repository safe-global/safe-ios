//
//  AssetsViewModel.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class BalancesViewModel: BasicLoadableViewModel {
    var balances = [TokenBalance]()
    private let safe: Safe

    init(safe: Safe) {
        self.safe = safe
        super.init()
    }

    override func reload() {
        Just(safe.address)
            .compactMap { $0 }
            .compactMap { Address($0) }
            .setFailureType(to: Error.self)
            .receive(on: DispatchQueue.global())
            .tryMap { address -> [TokenBalance] in
                let balancesResponse = try App.shared.safeTransactionService.safeBalances(at: address)
                let tokenBalances = balancesResponse.map { TokenBalance($0) }
                return tokenBalances
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
            }, receiveValue:{ [weak self] tokenBalances in
                guard let `self` = self else { return }
                self.balances = tokenBalances
                self.errorMessage = nil
            })
            .store(in: &subscribers)
    }
}
