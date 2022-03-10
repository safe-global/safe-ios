//
// Created by Vitaly on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class WCAppRegistryRepository {

    func delete(_ entry: WCAppRegistryEntry) {
        CDWCAppRegistryEntry.delete(by: entry.id)
    }

    func save(_ entry: WCAppRegistryEntry) {
        assert(Thread.isMainThread)

        // find or replace the object
        var cdEntry: CDWCAppRegistryEntry! = CDWCAppRegistryEntry.entry(by: entry.id)
        if cdEntry == nil {
            cdEntry = CDWCAppRegistryEntry.create()
        }

        // update the fields
        update(cdEntry: cdEntry, with: entry)

        // save the database
        App.shared.coreDataStack.saveContext()
    }

    private func update(cdEntry: CDWCAppRegistryEntry, with other: WCAppRegistryEntry) {
        cdEntry.id = other.id
        cdEntry.role = other.role.rawValue
        cdEntry.name = other.name
        cdEntry.shortName = other.shortName
        cdEntry.desc = other.description
        cdEntry.homepage = other.homepage
        cdEntry.imageId = other.imageId
        cdEntry.imageSmallURL = other.imageSmallUrl
        cdEntry.imageMediumURL = other.imageMediumUrl
        cdEntry.imageLargeURL = other.imageLargeUrl
        cdEntry.linkBrowser = other.linkBrowser
        cdEntry.linkMobileNative = other.linkMobileNative
        cdEntry.linkMobileUniversal = other.linkMobileUniversal
    }

    func entry(from other: CDWCAppRegistryEntry) -> WCAppRegistryEntry? {
        guard
                let entryId = other.id,
                let name = other.name,
                let chainsString = other.chains
                else {
            return nil
        }

        let result = WCAppRegistryEntry(
                id: entryId,
                role: WCAppRegistryEntry.Role(rawValue: other.role)!,
                chains: other.chains?.split(separator: ",").map(String.init) ?? [],
                versions: other.versions?.split(separator: ",").map(String.init) ?? [],
                name: name,
                shortName: other.shortName ?? "",
                description: other.desc,
                homepage: other.homepage,
                imageId: other.imageId,
                imageSmallUrl: other.imageSmallURL,
                imageMediumUrl: other.imageMediumURL,
                imageLargeUrl: other.imageLargeURL,
                linkBrowser: other.linkBrowser,
                linkMobileNative: other.linkMobileNative,
                linkMobileUniversal: other.linkMobileUniversal
        )

        return result
    }

}
