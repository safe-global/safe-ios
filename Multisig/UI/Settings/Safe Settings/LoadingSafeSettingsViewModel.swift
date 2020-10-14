//
//  LoadingSafeSettingsViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class LoadingSafeSettingsViewModel: ObservableObject, LoadingModel {
    var reloadSubject = PassthroughSubject<Void, Never>()
    var cancellables = Set<AnyCancellable>()
    var coreDataCancellable: AnyCancellable?
    @Published var status: ViewLoadingStatus = .initial
    @Published var result: Safe?

    init() {
        buildCoreDataPipeline()
        buildReload()
    }

    func buildReload() {
        buildReloadPipelineWith { upstream in
            upstream
                .selectedSafe()
                .receive(on: DispatchQueue.global())
                .tryMap { safe in
                    guard let addressString = safe.address else {
                        throw "Error: safe does not have address. Please reload."
                    }
                    let address = try Address(from: addressString)
                    let safeInfo = try Safe.download(at: address)
                    safe.update(from: safeInfo)
                    return safe
                }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
}


extension Safe {
    func update(from safeInfo: SafeStatusRequest.Response) {
        threshold = safeInfo.threshold.value
        owners = safeInfo.owners.map { $0.address }
        implementation = safeInfo.implementation.address
        version = safeInfo.version
        nonce = safeInfo.nonce.value
        modules = safeInfo.modules.map { $0.address }
        fallbackHandler = safeInfo.fallbackHandler.address
    }
}
