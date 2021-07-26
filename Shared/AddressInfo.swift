//
//  AddressInfo.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.03.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct AddressInfo {
    var address: Address
    var name: String?
    var logoUri: URL?
}

extension Address {
    var addressInfo: AddressInfo {
        .init(address: self, name: nil, logoUri: nil)
    }
}

extension AddressInfo {
    func combine(_ rhs: Self) -> Self {
        .init(address: rhs.address, name: rhs.name ?? name, logoUri: rhs.logoUri ?? logoUri)
    }
}
