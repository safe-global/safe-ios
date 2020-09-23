//
//  TransactionConfirmationViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class TransactionConfirmationViewModel: Equatable {

    var address: String = ""
    var data: String?

    init(address: String, data: String?) {
        (self.address, self.data) = (address, data)
    }

    init(confirmation: MultisigConfirmation) {
        address = confirmation.signer.address.checksummed
        data = confirmation.signature.data.toHexStringWithPrefix()
    }

    static func == (lhs: TransactionConfirmationViewModel, rhs: TransactionConfirmationViewModel) -> Bool {
        (lhs.address, lhs.data) == (rhs.address, rhs.data)
    }

}
