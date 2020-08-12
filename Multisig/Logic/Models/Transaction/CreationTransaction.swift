//
//  Transaction.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CreationTransaction: Decodable, Hashable {
    var transactionHash: DataString?
    var creator: AddressString?
    var setupData: DataString?
    var created: Date?
    var factoryAddress: AddressString?
    var masterCopy: AddressString?

    static func browserURL(hash: String) -> URL {
        App.configuration.services.etehreumBlockBrowserURL
            .appendingPathComponent("tx").appendingPathComponent(hash)
    }
}
