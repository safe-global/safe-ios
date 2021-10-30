//
//  NamingPolicy.swift
//  Multisig
//
//  Created by Moaaz on 10/30/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class NamingPolicy {
    static func name(for address: Address? = nil,
              info: AddressInfo? = nil,
              chainId: String) -> (name: String?, imageUri: URL?) {
        guard let addr = address ?? info?.address else { return (info?.name, info?.logoUri) }

        if let safeName = Safe.cachedName(by: AddressString(addr), chainId: chainId) {
            return (safeName, nil)
        } else if let ownerName = KeyInfo.name(address: addr) {
            return (ownerName, nil)
        } else if let entryName = AddressBookEntry.cachedName(by: AddressString(addr), chainId: chainId) {
            return (entryName, nil)
        }

        return (info?.name, info?.logoUri)
    }
}
