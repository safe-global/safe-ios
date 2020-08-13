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
    private var safeInfo: SafeStatusRequest.Response?
    private var nextURL: String?

    var canLoadNext: Bool {
        nextURL != nil
    }

    @Published var isLoadingNextPage: Bool = false {
        willSet { self.objectWillChange.send() }
    }

    let safe: Safe

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
                Future<TransactionsListViewModel, Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            self.safeInfo = try App.shared.safeTransactionService.safeInfo(at: address)
                            let transactions = try App.shared.safeTransactionService.transactions(address: address)
                            self.nextURL = transactions.next
                            var models = transactions.results.flatMap { TransactionViewModel.create(from: $0, self.safeInfo!) }
                            if let creationTransaction = try self.creationTransaction() {
                                models.append(creationTransaction)
                            }
                            let list = TransactionsListViewModel(models)
                            promise(.success(list))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
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
            }, receiveValue:{ [weak self] transactionsList in
                guard let `self` = self else { return }
                self.transactionsList = transactionsList
                self.errorMessage = nil
            })
            .store(in: &subscribers)
    }

    func loadNextPage() {
        subscribers.forEach { $0.cancel() }
        isLoadingNextPage = true
        Just(nextURL)
            .compactMap { $0 }
            .setFailureType(to: Error.self)
            .flatMap { url in
                Future<[TransactionViewModel], Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            if let transactions = try App.shared.safeTransactionService.loadTransactionsPage(url: url) {
                                self.nextURL = transactions.next
                                var models = transactions.results.flatMap { TransactionViewModel.create(from: $0, self.safeInfo!) }

                                // This should mean that we are on the last page on list
                                if let creationTransaction = try self.creationTransaction() {
                                    models.append(creationTransaction)
                                }
                                promise(.success(models))
                            }
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    App.shared.snackbar.show(message: error.localizedDescription)
                }
                self?.isLoadingNextPage = false
            }, receiveValue:{ [weak self] transactionsList in
                self?.transactionsList.add(transactionsList)
            })
            .store(in: &subscribers)
    }

    func isLast(transaction: TransactionViewModel) -> Bool {
        transactionsList.lastTransaction == transaction
    }

    func creationTransaction() throws -> CreationTransactionViewModel? {
        guard nextURL == nil else { return nil }

        let transaction = try App.shared.safeTransactionService.creationTransaction(address: Address(exactly: safe.address!))
        return CreationTransactionViewModel(transaction, self.safeInfo!)
    }
}
