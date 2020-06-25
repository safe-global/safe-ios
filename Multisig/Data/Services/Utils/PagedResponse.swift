//
//  SharedUtils.swift
//  Multisig
//
//  Created by Moaaz on 6/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct PagedResponse<Item: Decodable>: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Item]

    var nextPageRequest: PagedRequest<Item>? {
        PagedRequest<Item>(next)
    }

    var previousPageRequest: PagedRequest<Item>? {
        PagedRequest<Item>(previous)
    }
}
