//
//  CollectibleBalancesModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

struct CollectibleListSection: Identifiable {
    let id = UUID()
    var name: String
    var imageURL: URL?
    var collectibles: [CollectibleViewModel]

    var isEmpty: Bool {
        collectibles.isEmpty
    }
}

class CollectibleBalancesModel: ObservableObject, LoadingModel {
    var reloadSubject = PassthroughSubject<Void, Never>()
    var cancellables = Set<AnyCancellable>()
    var coreDataCancellable: AnyCancellable?
    @Published var status: ViewLoadingStatus = .initial
    @Published var result = [CollectibleListSection]()

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
                    try App.shared.safeTransactionService.collectibles(at: address)
                }
                .map {
                    CollectibleListSection.create($0)
                }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }

    }
}

extension CollectibleListSection {
    static func create(_  collectibles: [Collectible]) -> [Self] {
        let groupedCollectibles = Dictionary(grouping: collectibles, by: { $0.address })
        return groupedCollectibles.map { (key, value) in
            let token = App.shared.tokenRegistry[key!.address]
            let name = token?.name ?? value.first(where: { $0.tokenName != nil })?.tokenName ?? "Unknown"
            let logoURL = token?.logo ?? value.first(where: { $0.logoUri != nil })?.logoUri.flatMap { URL(string: $0) }
            let collectibles = value.compactMap { CollectibleViewModel(collectible: $0) }.sorted { $0.name < $1.name }
            return Self.init(name: name , imageURL: logoURL, collectibles: collectibles)
        }.sorted { $0.name < $1.name }
    }
}

extension Safe {
    static func selectedSafeAddress() -> Address? {
        assert(Thread.isMainThread)
        let context = App.shared.coreDataStack.viewContext
        let fr = Safe.fetchRequest().selected()
        guard let safe = (try? context.fetch(fr))?.first,
              let string = safe.address,
              let address = Address(string) else { return nil }
        return address
    }
}
