//
//  FlatCollectiblesListViewModel.swift
//  Multisig
//
//  Created by Vitaly on 28.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct FlatCollectiblesListViewModel {
    var items: [CollectibleListItem] = []
    var isEmpty: Bool {
        items.isEmpty
    }

    var next: String?

    init(_ items: [Collectible] = []) {
        var collectibleListItems: [CollectibleListItem] = []
        var currentNft: AddressString? = nil
        items.forEach { collectible in
            if currentNft != collectible.address {
                collectibleListItems.append(CollectibleListItem.header(CollectibleHeader(name: collectible.tokenName ?? "Unknown", logoURL: URL(string: collectible.logoUri ?? ""))))
                currentNft = collectible.address
            }
            collectibleListItems.append(CollectibleListItem.collectible(CollectibleItem(collectible: collectible)))
        }
        self.items = collectibleListItems
    }

    mutating func append(from list: Self) {
        self.next = list.next
        add(list.items)
    }

    mutating func add(_ models: [CollectibleListItem] = []) {
        self.items.append(contentsOf: models)
    }

    var lastTransaction: CollectibleListItem? {
        items.last
    }
}

enum CollectibleListItem: Decodable {
    case header(CollectibleHeader)
    case collectible(CollectibleItem)
}

struct CollectibleHeader: Decodable {
    let name: String
    let logoURL: URL?
}

struct CollectibleItem: Decodable {
    let collectible: Collectible
}
