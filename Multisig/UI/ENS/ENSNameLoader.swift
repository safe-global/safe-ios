//
//  ENSNameLoader.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class ENSNameLoader: ObservableObject {

    private var subscribers = Set<AnyCancellable>()

    @Published
    var isLoading: Bool = true

    init(safe: Safe) {
        Just(safe.address)
            .compactMap { $0 }
            .compactMap { Address($0) }
            .flatMap { address in
                Future { promise in
                    DispatchQueue.global().async {
                        let ensName = try? App.shared.ens.name(for: address)
                        promise(.success(ensName))
                    }
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
            }, receiveValue: { [unowned safe] ensName in
                safe.ensName = ensName
            })
            .store(in: &subscribers)
    }

}
