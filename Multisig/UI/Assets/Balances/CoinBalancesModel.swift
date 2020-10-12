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
    @Published var status: ViewLoadingStatus = .initial
    @Published var result = [TokenBalance]()

    init() {
        buildCoreDataPipeline()
        buildReloadPipeline { address in
            let balancesResponse = try App.shared.safeTransactionService.safeBalances(at: address)
            let tokenBalances = balancesResponse.map { TokenBalance($0) }
            return tokenBalances
        }
    }
}
