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
    let address: String
    let tokenID: String?
    let imageURL: URL?
    let website: URL?
    let websiteName: String?

    var hasName: Bool {
        !["", "Unknown"].contains(name)
    }
    
    init() {
        id = UUID()
        name = ""
        description = ""
        address = ""
        tokenID = ""
        websiteName = ""
        imageURL = nil
        website = nil
    }

    init(collectible: Collectible) {
        id = UUID()
        name = collectible.name ?? "Unknown"
        description = collectible.description ?? ""
        address = collectible.address?.address.checksummed ?? ""
        tokenID = collectible.id
        imageURL = URL(string: collectible.imageUri ?? "")
        website = nil
        websiteName = ""
    }
}
