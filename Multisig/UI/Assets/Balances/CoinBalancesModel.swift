//
//  CoinBalancesModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class CoinBalancesModel: ObservableObject, LoadingModel {
    var reloadSubject = PassthroughSubject<Void, Never>()
    var cancellables = Set<AnyCancellable>()
    var coreDataCancellable: AnyCancellable?
    @Published var status: ViewLoadingStatus = .initial
    @Published var result = [TokenBalance]()

    init() {
        buildCoreDataPipeline()
        buildReload()
    }

    func buildReload() {
        buildReloadPipelineWith { upstream in
            upstream
                .selectedSafe()
                .safeToAddress()
                .receive(on: DispatchQueue.global())
                .tryMap { address in
                    try App.shared.safeTransactionService.safeBalances(at: address)
                }
                .map {
                    $0.map { TokenBalance($0) }
                }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
}
