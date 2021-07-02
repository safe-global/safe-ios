//
//  CollectibleBalancesModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Combine
import Foundation

struct CollectibleListSection: Identifiable {
    let id = UUID()
    var name: String
    var imageURL: URL?
    var collectibles: [CollectibleViewModel]

    var isEmpty: Bool {
        collectibles.isEmpty
    }
}

extension CollectibleListSection {
    static func create(_  collectibles: [Collectible]) -> [Self] {
        let groupedCollectibles = Dictionary(grouping: collectibles, by: { $0.address })
        return groupedCollectibles.map { (key, value) in
            let name = value.first(where: { $0.tokenName != nil })?.tokenName ?? "Unknown"
            let logoURL = value.first(where: { $0.logoUri != nil })?.logoUri.flatMap { URL(string: $0) }
            let collectibles = value.compactMap { CollectibleViewModel(collectible: $0) }.sorted { $0.name < $1.name }
            return Self.init(name: name , imageURL: logoURL, collectibles: collectibles)
        }.sorted { $0.name < $1.name }
    }
}
