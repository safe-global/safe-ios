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
        let fork = resolve(address: safe.address)
            .share()
            .multicast { PassthroughSubject<String?, Never>() }
        fork
            .map { _ in false }
            .assign(to: \.isLoading, on: self)
            .store(in: &subscribers)
        fork
            .assign(to: \.ensName, on: safe)
            .store(in: &subscribers)
        fork
            .connect()
            .store(in: &subscribers)
    }

    func resolve(address: String?) -> AnyPublisher<String?, Never> {
        Just(address)
            .compactMap { $0 }
            .compactMap { Address($0) }
            .receive(on: DispatchQueue.global())
            .map { try? App.shared.ens.name(for: $0) }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

}
