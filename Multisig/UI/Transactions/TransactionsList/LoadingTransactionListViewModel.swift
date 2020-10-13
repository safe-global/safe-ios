//
//  LoadingTransactionListViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

class LoadingTransactionListViewModel: ObservableObject, LoadingModel {
    var reloadSubject = PassthroughSubject<Void, Never>()
    var cancellables = Set<AnyCancellable>()
    var coreDataCancellable: AnyCancellable?
    @Published var status: ViewLoadingStatus = .initial
    @Published var result = TransactionsListViewModel()

    var loadMoreSubject = PassthroughSubject<String?, Never>()
    @Published var loadMoreStatus: ViewLoadingStatus = .initial

    init() {
        buildCoreDataPipeline()
        buildLoadMorePipeline()
        buildReload()
    }

    func buildCoreDataPipeline() {
        coreDataCancellable =
            Publishers
            .onCoreDataSave
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                self.cancellables = .init()
                self.reloadSubject = .init()
                self.loadMoreSubject = .init()
                self.loadMoreStatus = .initial
                self.status = .initial
                self.buildReload()
                self.buildLoadMorePipeline()
            }
    }

    func buildReload() {
        buildReloadPipelineWith { upstream in
            upstream
                .selectedSafe()
                .safeToAddress()
                .receive(on: DispatchQueue.global())
                .tryMap { address in
                    try App.shared.clientGatewayService.transactionSummaryList(address: address)
                }
                .transformPageToList()
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }

    private func buildLoadMorePipeline() {
        let inputFork = loadMoreSubject
            .compactMap { $0 }

        inputFork
            .status(.loading, path: \.loadMoreStatus, object: self, set: &cancellables)

        let outputFork = inputFork
            .receive(on: DispatchQueue.global())
            .tryMap { url in
                try App.shared.clientGatewayService.transactionSummaryList(pageUri: url)
            }
            .transformPageToList()
            .transformToResult()
            .receive(on: RunLoop.main)
            .multicast { PassthroughSubject<Result<TransactionsListViewModel, Error>, Never>() }

        outputFork
            .handleError(statusPath: \.loadMoreStatus, object: self, set: &cancellables)

        outputFork
            .onSuccessResult()
            .status(.success, path: \.loadMoreStatus, object: self, set: &cancellables)

        outputFork
            .onSuccessResult()
            .sink { [weak self] in self?.result.append(from: $0) }
            .store(in: &cancellables)

        outputFork
            .connect()
            .store(in: &cancellables)
    }

    func loadMore() {
        loadMoreSubject.send(result.next)
    }

}

extension Publisher where Output == Address {

    func transactionList() -> AnyPublisher<Result<TransactionsListViewModel, Error>, Never> {
        self
            .receive(on: DispatchQueue.global())
            .tryMap { address in
                try App.shared.clientGatewayService.transactionSummaryList(address: address)
            }
            .transformPageToList()
            .transformToResult()
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}


extension Publisher {

    func selectedSafe() -> AnyPublisher<Safe, Error> {
        self
            .tryCompactMap { _ -> Safe? in
                let context = App.shared.coreDataStack.viewContext
                let fr = Safe.fetchRequest().selected()
                let safe = try context.fetch(fr).first
                return safe
            }
            .eraseToAnyPublisher()
    }

    func safeToAddress() -> AnyPublisher<Address, Error> where Output == Safe {
        self
            .tryCompactMap { safe in
                guard let address = safe.address else { return nil }
                return try Address(from: address)
            }
            .eraseToAnyPublisher()
    }

}


extension Publisher where Output == Page<TransactionSummary> {
    func transformPageToList() -> AnyPublisher<TransactionsListViewModel, Failure> {
        self
            .map { transactions -> TransactionsListViewModel in
                let models = transactions.results.flatMap { TransactionViewModel.create(from: $0) }
                var list = TransactionsListViewModel(models)
                list.next =  transactions.next
                return list
            }
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    func transformToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        self
            .map { value -> Result<Output, Failure> in .success(value) }
            .catch { error in
                Just(.failure(error))
            }
            .eraseToAnyPublisher()
    }
}

// Result<K, Failure>
extension Publisher {

    func handleError<Root, Success, Failed>(statusPath:  ReferenceWritableKeyPath<Root, ViewLoadingStatus>, object: Root, set: inout Set<AnyCancellable>) where Output == Result<Success, Failed>, Failure == Never {
        self
            .onFailedResult()
            .map { error -> Void in
                App.shared.snackbar.show(message: error.localizedDescription)
            }
            .status(.failure, path: statusPath, object: object, set: &set)
    }

    func status<Root>(_ status: ViewLoadingStatus, path: ReferenceWritableKeyPath<Root, ViewLoadingStatus>, object: Root, set: inout Set<AnyCancellable>) where Failure == Never {
        self
            .map { _ -> ViewLoadingStatus in status }
            .assign(to: path, on: object)
            .store(in: &set)
    }

    func onSuccessResult<Success, Failed>() -> AnyPublisher<Success, Never> where Output == Result<Success, Failed>, Failure == Never {
        self
            .compactMap { result -> Success? in
                guard case .success(let value) = result else { return nil }
                return value
            }
            .eraseToAnyPublisher()
    }

    func onFailedResult<Success, Failed>() -> AnyPublisher<Failed, Never> where Output == Result<Success, Failed>, Failure == Never {
        self
            .compactMap { result -> Failed? in
                guard case .failure(let value) = result else { return nil }
                return value
            }
            .eraseToAnyPublisher()
    }

}


extension Publishers {

    static var onCoreDataSave: AnyPublisher<Notification, Never> {
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: App.shared.coreDataStack.viewContext)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }


}

protocol LoadingModel: class {
    associatedtype ResultType
    var status: ViewLoadingStatus { get set }
    var result: ResultType { get set }
    var reloadSubject: PassthroughSubject<Void, Never> { get set }
    var cancellables: Set<AnyCancellable> { get set }
    var coreDataCancellable: AnyCancellable? { get set }

    func buildReload()
}

extension LoadingModel {

    func buildCoreDataPipeline() {
        coreDataCancellable =
            Publishers
            .onCoreDataSave
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                self.cancellables = .init()
                self.reloadSubject = .init()
                self.status = .initial
                self.buildReload()
            }
    }

    func buildReloadPipelineWith<Failure>(loadData: (AnyPublisher<Void, Never>) -> AnyPublisher<ResultType, Failure>) {
        reloadSubject
            .status(.loading, path: \.status, object: self, set: &cancellables)

        let outputFork =
            loadData(reloadSubject.eraseToAnyPublisher())
            .transformToResult()
            .multicast { PassthroughSubject<Result<ResultType, Failure>, Never>() }

        outputFork
            .onSuccessResult()
            .assign(to: \.result, on: self)
            .store(in: &cancellables)

        outputFork
            .onSuccessResult()
            .status(.success, path: \.status, object: self, set: &cancellables)

        outputFork
            .handleError(statusPath: \.status, object: self, set: &cancellables)

        outputFork
            .connect()
            .store(in: &cancellables)
    }


    func reload() {
        reloadSubject.send()
    }

}
