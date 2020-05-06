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
    var isLoading: Bool = false

    func load(safe: Safe) {
        subscribers.forEach { $0.cancel() }

        let atTheBeginning = Just(safe.address)

        atTheBeginning
            .map { _ in true }
            .assign(to: \.isLoading, on: self)
            .store(in: &subscribers)

        let atTheEnd = atTheBeginning
            .compactMap { $0 }
            .compactMap { Address($0) }
            .receive(on: DispatchQueue.global())
            .map { try? App.shared.ens.name(for: $0) }
            .receive(on: RunLoop.main)

        atTheEnd
            .assign(to: \.ensName, on: safe)
            .store(in: &subscribers)

        atTheEnd
            .map { _ in false }
            .assign(to: \.isLoading, on: self)
            .store(in: &subscribers)
    }
}
