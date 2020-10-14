//
//  Collectible.swift
//  Multisig
//
//  Created by Moaaz on 7/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct Collectible: Decodable, Hashable {
    let address: AddressString?
    let tokenName: String?
    let tokenSymbol:String?
    let id: String?
    let uri: String?
    let name: String?
    let description: String?
    let imageUri: String?
    let metadata: CollectibleMetaData?
    let logoUri: String?
}
