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
    var total: String = "0.00"

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
                .tryCompactMap { [weak self] address -> SafeBalanceSummary? in
                    guard let `self` = self else { return nil }
                    let summary = try App.shared.clientGatewayService.balances(address: address)
                    self.total = TokenBalance.displayCurrency(from: summary.fiatTotal)
                    return summary
                }
                .map {
                    $0.items.map { TokenBalance($0) }
                }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
}
