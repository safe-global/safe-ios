//
//  Address+Solidity.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity

extension Address {
    init(_ solAddress: Sol.Address) {
        let data = solAddress.encode()
        let bytes20 = Data(Array(data).suffix(20))
        self.init(bytes20)!
    }
}

extension AddressString {
    init(_ address: Sol.Address) {
        self.init(Address(address))
    }
}
