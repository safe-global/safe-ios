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
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] address -> TransactionsListViewModel in
                let transactions = try App.shared.clientGatewayService.transactionSummaryList(address: address)                
                let models = transactions.results.flatMap { TransactionViewModel.create(from: $0) }
                if let `self` = self {
                    self.nextURL = transactions.next
                }
                let list = TransactionsListViewModel(models)
                return list
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
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] url -> [TransactionViewModel] in
                let transactions = try App.shared.clientGatewayService.transactionSummaryList(pageUri: url)
                let models = transactions.results.flatMap { TransactionViewModel.create(from: $0) }
                if let `self` = self {
                    self.nextURL = transactions.next
                }
                return models
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
}
