//
//  LoadingTransactionListViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

class LoadingTransactionListViewModel: ObservableObject {
    var list = TransactionsListViewModel()
    @Published
    var status: ViewLoadingStatus = .initial
    @Published
    var loadMoreStatus: ViewLoadingStatus = .initial
    var subscribers = Set<AnyCancellable>()

    let coreDataPublisher = NotificationCenter.default
        .publisher(for: .NSManagedObjectContextDidSave,
                   object: App.shared.coreDataStack.viewContext)
        .receive(on: RunLoop.main)

    var reactOnCoreData: AnyCancellable!

    init() {
        reactOnCoreData = coreDataPublisher
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                self.status = .initial
            }
    }

    func reload() {
        subscribers.removeAll()
        status = .loading
        Just(())
            .tryCompactMap { _ -> String? in
                let context = App.shared.coreDataStack.viewContext
                let fr = Safe.fetchRequest().selected()
                let safe = try context.fetch(fr).first
                return safe?.address
            }
            .compactMap { Address($0) }
            .receive(on: DispatchQueue.global())
            .tryMap { address -> TransactionsListViewModel in
                let transactions = try App.shared.clientGatewayService.transactionSummaryList(address: address)
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
                    self.status = .failure
                } else {
                    self.status = .success
                }
            }, receiveValue:{ [weak self] value in
                guard let `self` = self else { return }
                self.list = value
            })
            .store(in: &subscribers)
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
            .store(in: &subscribers)
    }

}
