//
// Created by Vitaly on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class WCAppRegistryRepository {

    func entries(searchTerm: String? = nil, role: WCAppRegistryEntry.Role = .wallet) -> [WCAppRegistryEntry] {
        assert(Thread.isMainThread)
        let entries = try? CDWCAppRegistryEntry.entries(name: searchTerm, role: role.rawValue)
        return entries?.compactMap {
            entry(from: $0)
        } ?? []
    }

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

    /// replaces all existing entries with new ones
    func updateEntries(_ entries: [WCAppRegistryEntry]) {
        assert(Thread.isMainThread)
        let context = App.shared.coreDataStack.viewContext



        // delete all existing entries
        guard let cdEntries = (try? CDWCAppRegistryEntry.getAll()) else {
            return
        }
        var keysByEntry: [String: NSSet] = [:]
        for entry in cdEntries {
            // keep relationship between existing entry and a key
            if let id = entry.id, let keys = entry.keys {
                keysByEntry[id] = keys
            }
            context.delete(entry)
        }

        // save new entries
        for entry in entries {
            let cdEntry = CDWCAppRegistryEntry.create()
            update(cdEntry: cdEntry, with: entry)
            // restore relationship to the key
            cdEntry.keys = keysByEntry[entry.id]
        }

        App.shared.coreDataStack.saveContext()
    }

    private func update(cdEntry: CDWCAppRegistryEntry, with other: WCAppRegistryEntry) {
        cdEntry.id = other.id
        cdEntry.role = other.role.rawValue
        cdEntry.chains = other.chains.joined(separator: ",")
        cdEntry.versions = other.versions.joined(separator: ",")
        cdEntry.name = other.name
        cdEntry.rank = Int64(other.rank)
        cdEntry.shortName = other.shortName
        cdEntry.desc = other.description
        cdEntry.homepage = other.homepage
        cdEntry.imageId = other.imageId
        cdEntry.imageSmallURL = other.imageSmallUrl
        cdEntry.imageMediumURL = other.imageMediumUrl
        cdEntry.imageLargeURL = other.imageLargeUrl
        cdEntry.appStoreLink = other.appStoreLink
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
                chains: chainsString.split(separator: ",").map(String.init),
                versions: other.versions?.split(separator: ",").map(String.init) ?? [],
                name: name,
                rank: Int(other.rank),
                shortName: other.shortName,
                description: other.desc,
                homepage: other.homepage,
                imageId: other.imageId,
                imageSmallUrl: other.imageSmallURL,
                imageMediumUrl: other.imageMediumURL,
                imageLargeUrl: other.imageLargeURL,
                appStoreLink: other.appStoreLink,
                linkMobileNative: other.linkMobileNative,
                linkMobileUniversal: other.linkMobileUniversal
        )

        return result
    }

    func entry(from other: JsonAppRegistryEntry, role: WCAppRegistryEntry.Role = .wallet, rank: Int = 0) -> WCAppRegistryEntry? {
        // filter and map chains from caip-2 format to just chain id
        let chains = other.chains.compactMap { caip2 -> String? in
            var caip2 = caip2
            if caip2.hasPrefix("eip155:") {
                caip2.removeFirst("eip155:".count)
                return caip2
            }
            return nil
        }

        guard
                !other.name.isEmpty,
                !chains.isEmpty,
                let appStoreLink = other.app.ios.url ?? other.app.browser.url
                else {
            return nil
        }
        let result = WCAppRegistryEntry(
                id: other.id,
                role: role,
                chains: chains,
                versions: other.versions,
                name: other.name,
                rank: rank,
                shortName: other.metadata.shortName,
                description: other.description,
                homepage: other.homepage.url,
                imageId: other.image_id,
                imageSmallUrl: other.image_url.sm.url,
                imageMediumUrl: other.image_url.md.url,
                imageLargeUrl: other.image_url.lg.url,
                appStoreLink: appStoreLink,
                linkMobileNative: other.mobile.native.url,
                linkMobileUniversal: other.mobile.universal.url
        )

        return result
    }
}
