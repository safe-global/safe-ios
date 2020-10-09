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

class CollectibleBalancesModel: NetworkContentViewModel {
    var sections = [CollectibleListSection]()

    func reload() {
        super.reload { safe -> [CollectibleListSection] in
            guard let addressString = safe.address else {
                throw "Error: safe does not have address. Please reload."
            }
            let address = try Address(from: addressString)
            let collectibles = try App.shared.safeTransactionService.collectibles(at: address)
            let models = CollectibleListSection.create(collectibles)
            return models
        } receive: { [weak self] values in
            guard let `self` = self else { return }
            self.sections = values
        }
    }
}

extension CollectibleListSection {
    static func create(_  collectibles: [Collectible]) -> [Self] {
        let groupedCollectibles = Dictionary(grouping: collectibles, by: { $0.address })
        return groupedCollectibles.map { (key, value) in
            let token = App.shared.tokenRegistry[key!.address]
            let name = token?.name ?? "Unknown"
            let logoURL = token?.logo
            let collectibles = value.compactMap { CollectibleViewModel(collectible: $0) }.sorted { $0.name < $1.name }

            return Self.init(name: name , imageURL: logoURL, collectibles: collectibles)
        }.sorted { $0.name < $1.name }
    }
}

