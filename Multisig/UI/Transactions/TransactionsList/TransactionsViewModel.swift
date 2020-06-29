//
//  TransactionListViewModel.swift
//  Multisig
//
//  Created by Moaaz on 5/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class TransactionsViewModel: ObservableObject {
    @Published var transactionsList = TransactionsListViewModel()
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private var prevURL: String?
    private var nextURL: String?

    var safe: Safe? {
        didSet {
            guard oldValue != safe && safe != nil else {
                return
            }
            loadData()
        }
    }

    var safeInfo: SafeStatusRequest.Response?

    var subscribers = Set<AnyCancellable>()

    func loadData() {
        subscribers.forEach { $0.cancel() }
        isLoading = true
        Just(safe!.address!)
            .compactMap { Address($0) }
            .setFailureType(to: Error.self)
            .flatMap { address in
                Future<TransactionsListViewModel, Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            self.safeInfo = try App.shared.safeTransactionService.safeInfo(at: address)
                            let transactions = try App.shared.safeTransactionService.transactions(address: address)
                            self.prevURL = transactions.previous
                            self.nextURL = transactions.next
                            let models = transactions.results.flatMap { TransactionViewModel.create(from: $0, self.safeInfo!) }
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
                }
                self.isLoading = false
            }, receiveValue:{ transactionsList in
                self.transactionsList = transactionsList
            })
            .store(in: &subscribers)
    }

    func loadNextPage() {
        subscribers.forEach { $0.cancel() }
        Just(nextURL)
            .setFailureType(to: Error.self)
            .flatMap { url in
                Future<[TransactionViewModel], Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            if let transactions = try App.shared.safeTransactionService.loadTransactionsPage(url: url!) {
                                self.nextURL = transactions.next
                                let models = transactions.results.flatMap { TransactionViewModel.create(from: $0, self.safeInfo!) }
                                promise(.success(models))
                            }
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Error should be displayed here
                }
            }, receiveValue:{ transactionsList in
                self.transactionsList.add(transactionsList)
            })
            .store(in: &subscribers)
    }

    var canLoadNext: Bool {
        nextURL != nil
    }

    func isLast(transaction: TransactionViewModel) -> Bool {
        transactionsList.lastTransaction == transaction
    }
}
