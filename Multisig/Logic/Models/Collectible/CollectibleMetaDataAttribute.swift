//
//  CollectibleMetaDataAttribute.swift
//  Multisig
//
//  Created by Moaaz on 7/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CollectibleMetaDataAttribute: Codable, Hashable {
    let displayType: String?
    let traitType: String?
    let value: Int?
}
