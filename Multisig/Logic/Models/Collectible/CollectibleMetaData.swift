//
//  CollectibleMetaData.swift
//  Multisig
//
//  Created by Moaaz on 7/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CollectibleMetaData: Decodable, Hashable {
    let name: String?
    let description: String?
    let image: String?
}
