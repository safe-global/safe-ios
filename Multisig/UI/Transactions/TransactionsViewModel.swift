//
//  TransactionListViewModel.swift
//  Multisig
//
//  Created by Moaaz on 5/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine
import SwiftCryptoTokenFormatter
import BigInt

struct TransactionsList {
    private var transactions: [Transaction]
    init(_ response: TransactionsRequest.Response? = nil) {
        transactions = response?.results ?? []
    }

    var isEmpty: Bool {
        return historyTransactions.isEmpty && queuedTransactions.isEmpty
    }

    var historyTransactions: [Transaction] {
        return transactions
    }

    var queuedTransactions: [Transaction] {
        return transactions
    }
}

class TransactionsViewModel: ObservableObject {
    @Published var transactionsList = TransactionsList()

    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil


    private let safe: Safe
    private var subscribers = Set<AnyCancellable>()

    init(safe: Safe) {
        self.safe = safe
        loadData()
    }

    func loadData() {
        isLoading = true
        Just(safe.address!)
            .setFailureType(to: Error.self)
            .flatMap { address in
                Future<TransactionsList, Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            let balancesResponse = try App.shared.safeTransactionService.transactions(address: address)
                            promise(.success(TransactionsList(balancesResponse)))
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
            }, receiveValue:{ transactionsList in
                self.transactionsList = transactionsList
            })
            .store(in: &subscribers)
    }
}
