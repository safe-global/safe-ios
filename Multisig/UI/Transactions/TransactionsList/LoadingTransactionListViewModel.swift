//
//  LoadingTransactionListViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

class LoadingTransactionListViewModel: NetworkContentViewModel {
    var list = TransactionsListViewModel()
    @Published
    var loadMoreStatus: ViewLoadingStatus = .initial
    private var otherSubscribers = Set<AnyCancellable>()

    func reload() {
        super.reload { safe -> TransactionsListViewModel in
            guard let addressString = safe.address else {
                throw "Error: safe does not have address. Please reload."
            }
            let address = try Address(from: addressString)
            let transactions = try App.shared.clientGatewayService.transactionSummaryList(address: address)
            let models = transactions.results.flatMap { TransactionViewModel.create(from: $0) }
            var list = TransactionsListViewModel(models)
            list.next =  transactions.next
            return list

        } receive: { [weak self] value in
            guard let `self` = self else { return }
            self.list = value
        }
    }

    func loadMore() {
        guard loadMoreStatus != .loading else { return }
        loadMoreStatus = .loading
        Just(list.next)
            .compactMap { $0 }
            .receive(on: DispatchQueue.global())
            .tryMap { url -> TransactionsListViewModel in
                let transactions = try App.shared.clientGatewayService.transactionSummaryList(pageUri: url)
                let models = transactions.results.flatMap { TransactionViewModel.create(from: $0) }
                var list = TransactionsListViewModel(models)
                list.next =  transactions.next
                return list
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let `self` = self else { return }
                if case .failure(let error) = completion {
                    App.shared.snackbar.show(message: error.localizedDescription)
                    self.loadMoreStatus = .failure
                } else {
                    self.loadMoreStatus = .success
                }
            }, receiveValue:{ [weak self] value in
                guard let `self` = self else { return }
                self.list.append(from: value)
            })
            .store(in: &otherSubscribers)
    }

}

