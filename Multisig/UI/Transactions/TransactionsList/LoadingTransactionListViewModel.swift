//
//  LoadingTransactionListViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

import Combine

class LoadingTransactionListViewModel: ObservableObject {

    // MARK: - Inputs

    // signals that reload is needed
    private var reloadSubject: PassthroughSubject<Void, Never>

    // url of the next page to load
    private var loadMoreSubject: PassthroughSubject<String?, Never>

    // Storage for subscribers
    private var cancellables: Set<AnyCancellable> = .init()

    // MARK: - Outputs
    @Published var status: ViewLoadingStatus = .initial
    @Published var loadMoreStatus: ViewLoadingStatus = .initial
    @Published var list: TransactionsListViewModel = .init()

    // MARK: - Pipeline
    init() {
        // This sets up 3 pipelines according to the 3 possible input actions
        // I. on Core Data save() -> update outputs: status (reset status to .initial to trigger the reload() action automatically)
        // II. on reload() -> load first page of transactions for the selected safe -> update outputs: status, list
        // III. on loadMore() -> load next page of transactions -> update outputs: loadMoreStatus, list

        // required inits
        reloadSubject = .init()
        loadMoreSubject = .init()

        // I. on Core Data save() ->
        //   a) set status = .initial to trigger the reload() on appearance
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave,
                       object: App.shared.coreDataStack.viewContext)
            .map { notification -> ViewLoadingStatus in
                .initial
            }
            .receive(on: RunLoop.main)
            .assign(to: \.status, on: self)
            .store(in: &cancellables)

        // II. on reload() ->
        //   fork into 2 streams:
        let reloadInputFork = reloadSubject
            .receive(on: RunLoop.main)
            .multicast { PassthroughSubject<Void, Never>() }

        defer {
            reloadInputFork
                .connect()
                .store(in: &cancellables)
        }

        //   a) status = .loading
        reloadInputFork
            .map { ViewLoadingStatus.loading }
            .assign(to: \.status, on: self)
            .store(in: &cancellables)

        //   b) load first page of transactions of the selected safe
        let getTransactionList = reloadInputFork

            //      i. fetch selected safe from Core Data
            .tryCompactMap { _ -> Safe? in
                let context = App.shared.coreDataStack.viewContext
                let fr = Safe.fetchRequest().selected()
                let safe = try context.fetch(fr).first
                return safe
            }

            //      ii. get its address
            .compactMap { safe in safe.address }
            .tryMap { try Address(from: $0) }

            //      iii. get transaction list by address
            .receive(on: DispatchQueue.global())
            .tryMap { address in
                try App.shared.clientGatewayService.transactionSummaryList(address: address)
            }

            //      iv. transform response list to success<view model list>
            .map { transactions -> TransactionsListViewModel in
                let models = transactions.results.flatMap { TransactionViewModel.create(from: $0) }
                var list = TransactionsListViewModel(models)
                list.next =  transactions.next
                return list
            }
            .map { list -> Result<TransactionsListViewModel, Error> in
                .success(list)
            }

            //      v. transform response error to failure<error>
            .catch { error in
                Just(.failure(error))
            }

        //      vi. update outputs
        //          fork into 3 subscribers:
        let reloadOutputFork = getTransactionList
            .receive(on: RunLoop.main)
            .multicast {
                PassthroughSubject<Result<TransactionsListViewModel, Error>, Never>()
            }

        defer {
            reloadOutputFork
                .connect()
                .store(in: &cancellables)
        }

        //          1. on success<list>: status = .success
        let reloadSuccess = reloadOutputFork
            .compactMap { result -> TransactionsListViewModel? in
                switch result {
                case .success(let value): return value
                default: return nil
                }
            }

        reloadSuccess
            .map { _ -> ViewLoadingStatus in
                .success
            }
            .assign(to: \.status, on: self)
            .store(in: &cancellables)

        //          2. on succes<list>: self.list = list
        reloadSuccess
            .assign(to: \.list, on: self)
            .store(in: &cancellables)


        //          3. on failure<error>: show error; set status = .failure
        reloadOutputFork
            .compactMap { result -> Error? in
                switch result {
                case .failure(let error): return error
                default: return nil
                }
            }
            .map { error -> ViewLoadingStatus in
                App.shared.snackbar.show(message: error.localizedDescription)
                return .failure
            }
            .assign(to: \.status, on: self)
            .store(in: &cancellables)


        // III. on loadMore(nextPageURL) ->

        //   fork into 2 streams:
        let loadMoreInputFork = loadMoreSubject
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .multicast { PassthroughSubject<String, Never>() }

        defer {
            loadMoreInputFork
                .connect()
                .store(in: &cancellables)
        }

        //  a) loadMoreStatus = .loading
        loadMoreInputFork
            .map { url -> ViewLoadingStatus in .loading }
            .assign(to: \.loadMoreStatus, on: self)
            .store(in: &cancellables)


        //  b) load next page of transactions using nextPageURL
        //      i. get next page of transactions
        //      ii. transform response list to success<view model list>
        //      iii. transform response error to failure<error>
        let loadMoreResults = loadMoreInputFork
            .receive(on: DispatchQueue.global())
            .tryMap { url in
                try App.shared.clientGatewayService.transactionSummaryList(pageUri: url)
            }
            .map { transactions -> TransactionsListViewModel in
                let models = transactions.results.flatMap { TransactionViewModel.create(from: $0) }
                var list = TransactionsListViewModel(models)
                list.next =  transactions.next
                return list
            }
            .map { list -> Result<TransactionsListViewModel, Error> in
                .success(list)
            }
            .catch { error in
                Just(.failure(error))
            }
            .receive(on: RunLoop.main)

        //      iv. update outputs
        //          fork into 3 subscribers:
        let loadMoreOutputFork = loadMoreResults
            .multicast { PassthroughSubject<Result<TransactionsListViewModel, Error>, Never>() }

        defer {
            loadMoreOutputFork
                .connect()
                .store(in: &cancellables)
        }

        let loadMoreSuccess = loadMoreOutputFork
            .compactMap { result -> TransactionsListViewModel? in
                switch result {
                case .success(let value): return value
                default: return nil
                }
            }

        //          1. on success<list>: loadMoreStatus = .success
        loadMoreSuccess
            .map { value -> ViewLoadingStatus in
                .success
            }
            .assign(to: \.loadMoreStatus, on: self)
            .store(in: &cancellables)

        //          2. on success<list>: append list to self.list
        loadMoreSuccess
            .sink { [weak self] list in
                guard let `self` = self else { return }
                self.list.append(from: list)
            }
            .store(in: &cancellables)

        //          3. on failure<error>: show error; loadMoreStatus = .failure
        loadMoreOutputFork
            .compactMap { result -> Error? in
                switch result {
                case .failure(let error): return error
                default: return nil
                }
            }
            .map { error -> ViewLoadingStatus in
                App.shared.snackbar.show(message: error.localizedDescription)
                return .failure
            }
            .assign(to: \.loadMoreStatus, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func reload() {
        reloadSubject.send()
    }

    func loadMore() {
        loadMoreSubject.send(list.next)
    }
}
