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
            .receive(on: DispatchQueue.global())
            .map { try? App.shared.ens.name(for: $0) }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                self.isLoading = false
            }, receiveValue: { ensName in
                safe.ensName = ensName
            })
            .store(in: &subscribers)
    }

}
