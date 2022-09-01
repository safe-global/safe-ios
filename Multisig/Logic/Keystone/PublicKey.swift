//
//  PublicKey.swift
//  Multisig
//
//  Created by Zhiying Fan on 27/8/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

struct PublicKey {
    typealias KeyID = String
    
    var id: KeyID
    private(set) var _store: EthereumPublicKey
    
    var address: Address {
        Address(_store.address)
    }
    
    var keyData: Data {
        Data(_store.rawPublicKey)
    }
    
    init(data: Data) throws {
        _store = try EthereumPublicKey(data)
        self.id = Self.identifier(Address(_store.address))
    }
    
    static func identifier(_ address: Address) -> KeyID {
        KeychainKey.ownerPublicKey + address.checksummed
    }
}
