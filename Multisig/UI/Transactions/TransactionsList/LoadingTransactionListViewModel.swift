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
    var loadMoreCancellables = Set<AnyCancellable>()
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
                self.loadMoreCancellables = .init()
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
            .status(.loading, path: \.loadMoreStatus, object: self, set: &loadMoreCancellables)

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
            .handleError(statusPath: \.loadMoreStatus, object: self, set: &loadMoreCancellables)

        outputFork
            .onSuccessResult()
            .status(.success, path: \.loadMoreStatus, object: self, set: &loadMoreCancellables)

        outputFork
            .onSuccessResult()
            .sink { [weak self] in self?.result.append(from: $0) }
            .store(in: &loadMoreCancellables)

        outputFork
            .connect()
            .store(in: &loadMoreCancellables)
    }

    func loadMore() {
        self.loadMoreCancellables = .init()
        self.loadMoreSubject = .init()
        self.loadMoreStatus = .initial
        self.buildLoadMorePipeline()
        loadMoreSubject.send(result.next)
    }

}
