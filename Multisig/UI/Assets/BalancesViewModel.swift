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
        reloadData()
    }

    override func reload() {
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
                self.isRefreshing = false
            }, receiveValue:{ tokenBalances in
                self.balances = tokenBalances
                self.errorMessage = nil
            })
            .store(in: &subscribers)
    }
}
