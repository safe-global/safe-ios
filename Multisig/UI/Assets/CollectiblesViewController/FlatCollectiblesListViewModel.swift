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
        guard case let .collectible(collectibleItem) = items.last, let previousPageLastNft = collectibleItem.collectible.address else {
            return
        }
        // models[0] always contains a header because it is a very first section on the page, and the header was added manually before.
        guard case let .collectible(collectibleItem) = models[1], let currentPageFirstNft = collectibleItem.collectible.address else {
            return
        }
        // The 'header separator' items are inserted manually after downloading the collectibles.
        // This results in duplicated headers if the same section is split between different pages of response.
        // We have to remove such headers.
        if previousPageLastNft == currentPageFirstNft {
            self.items.append(contentsOf: models.dropFirst(1))
        } else {
            self.items.append(contentsOf: models)
        }
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
