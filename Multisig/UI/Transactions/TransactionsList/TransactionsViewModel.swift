//
//  TransactionListViewModel.swift
//  Multisig
//
//  Created by Moaaz on 5/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class TransactionsViewModel: BasicLoadableViewModel {
    var transactionsList = TransactionsListViewModel()

    var safe: Safe? {
        didSet {
            guard oldValue != safe && safe != nil else {
                return
            }
            reloadData()
        }
    }

    override func reload() {
        Just(safe!.address!)
            .compactMap { Address($0) }
            .setFailureType(to: Error.self)
            .flatMap { address in
                Future<TransactionsListViewModel, Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            let info = try App.shared.safeTransactionService.safeInfo(at: address)
                            let transactions = try App.shared.safeTransactionService.transactions(address: address)
                            let models = transactions.results.flatMap { TransactionViewModel.create(from: $0, info) }
                            let list = TransactionsListViewModel(models)
                            promise(.success(list))
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
                    App.shared.viewState.show(message: error.localizedDescription)
                }
                self.isLoading = false
                self.isRefreshing = false
            }, receiveValue:{ transactionsList in
                self.transactionsList = transactionsList
                self.errorMessage = nil
            })
            .store(in: &subscribers)
    }
}
