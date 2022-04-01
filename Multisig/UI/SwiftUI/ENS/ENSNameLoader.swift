//
//  ENSNameLoader.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

protocol ENSNameLoaderDelegate {
    func ensNameLoaderDidLoadName(_ loader: ENSNameLoader)
}

class ENSNameLoader: ObservableObject {
    private var subscribers = Set<AnyCancellable>()
    private var delegate: ENSNameLoaderDelegate?

    @Published
    var isLoading: Bool = true

    init(safe: Safe, delegate: ENSNameLoaderDelegate? = nil) {
        self.delegate = delegate
        Just(safe.address!)
            .compactMap { Address($0) }
            .receive(on: DispatchQueue.global())
            .map { address -> String? in
                let chain = safe.chain!

                if let ensRegistryAddress = AddressString(chain.ensRegistryAddress ?? "") {
                    let manager = BlockchainDomainManager(rpcURL: chain.authenticatedRpcUrl,
                                                          chainId: chain.id!,
                                                          ensRegistryAddress: ensRegistryAddress)
                    return manager.ensName(for: address)
                }

                return nil
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
            }, receiveValue: { [weak self, unowned safe] ensName in
                safe.ensName = ensName
                guard let `self` = self else { return }
                self.delegate?.ensNameLoaderDidLoadName(self)
            })
            .store(in: &subscribers)
    }

}
