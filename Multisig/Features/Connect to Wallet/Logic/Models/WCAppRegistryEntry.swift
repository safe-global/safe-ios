//
// Created by Vitaly on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class WCAppRegistryEntry {

    var id: String

    var role: Role

    var name: String
    
    var rank: Int

    var shortName: String? = nil

    var description: String? = nil

    var homepage: URL? = nil

    var imageId: String? = nil

    var imageSmallUrl: URL? = nil

    var imageMediumUrl: URL? = nil

    var imageLargeUrl: URL? = nil

    var appStoreLink: URL? = nil

    var linkMobileNative: URL? = nil

    var linkMobileUniversal: URL? = nil

    var chains: [String]

    var versions: [String]

    init(
            id: String,
            role: Role,
            chains: [String],
            versions: [String],
            name: String,
            rank: Int,
            shortName: String? = nil,
            description: String? = nil,
            homepage: URL? = nil,
            imageId: String? = nil,
            imageSmallUrl: URL? = nil,
            imageMediumUrl: URL? = nil,
            imageLargeUrl: URL? = nil,
            appStoreLink: URL? = nil,
            linkMobileNative: URL? = nil,
            linkMobileUniversal: URL? = nil
    ) {
        self.id = id
        self.role = role
        self.chains = chains
        self.versions = versions
        self.name = name
        self.rank = rank
        self.shortName = shortName
        self.description = description
        self.homepage = homepage
        self.imageId = imageId
        self.imageSmallUrl = imageSmallUrl
        self.imageMediumUrl = imageMediumUrl
        self.imageLargeUrl = imageLargeUrl
        self.appStoreLink = appStoreLink
        self.linkMobileNative = linkMobileNative
        self.linkMobileUniversal = linkMobileUniversal

    }

    enum Role: Int16 {

        case wallet = 0

        case dapp = 1
    }
}

