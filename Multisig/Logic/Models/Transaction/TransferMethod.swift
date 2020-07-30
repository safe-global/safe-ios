//
//  TransferMethod.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransferMethod {
    var from: Address?
    var to: Address
    var amount: UInt256
}

extension TransferMethod {

    init(_ t: SmartContractMethodCall) {
        if let t = t as? MethodRegistry.ERC721.SafeTransferFromData {
            self.init(t)
        } else if let t = t as? MethodRegistry.ERC721.SafeTransferFrom {
            self.init(t)
        } else if let t = t as? MethodRegistry.ERC20.TransferFrom {
            self.init(t)
        } else if let t = t as? MethodRegistry.ERC20.Transfer {
            self.init(t)
        } else {
            LogService.shared.error(
                "Unexpected method call \(t) in transfer method",
                error: MethodDecodingError.unexpectedMethod(String(describing: t))
            )
            fatalError("Unexpected type of the method call")
        }
    }

    init(_ t: MethodRegistry.ERC721.SafeTransferFromData) {
        from = t.from
        to = t.to
        amount = 1
    }

    init(_ t: MethodRegistry.ERC721.SafeTransferFrom) {
        from = t.from
        to = t.to
        amount = 1
    }

    init(_ t: MethodRegistry.ERC20.TransferFrom) {
        from = t.from
        to = t.to
        amount = t.amount
    }

    init(_ t: MethodRegistry.ERC20.Transfer) {
        from = nil
        to = t.to
        amount = t.amount
    }

}
