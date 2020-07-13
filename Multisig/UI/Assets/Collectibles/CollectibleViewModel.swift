//
//  CollectiblesViewModel.swift
//  Multisig
//
//  Created by Moaaz on 7/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CollectibleViewModel: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let imageURL: URL?
    let hasName: Bool
    
    init() {
        id = UUID()
        name = ""
        description = ""
        imageURL = nil
        hasName = false
    }

    init(collectible: Collectible) {
        id = UUID()

        name = collectible.name ?? "Unknown"
        hasName = !(collectible.name == nil || collectible.name!.isEmpty)
        description = collectible.description ?? ""
        imageURL = URL(string: collectible.imageUri ?? "")
    }
}
