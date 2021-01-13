//
//  CollectiblesViewModel.swift
//  Multisig
//
//  Created by Moaaz on 7/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CollectibleViewModel: Identifiable {
    var id: UUID
    var name: String
    var description: String
    var address: String
    var tokenID: String?
    var imageURL: URL?
    var website: URL?
    var websiteName: String?

    var hasName: Bool {
        !["", "Unknown"].contains(name)
    }
}

extension CollectibleViewModel {
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
