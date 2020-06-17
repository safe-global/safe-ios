//
//  TransactionConfirmationViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class TransactionConfirmationViewModel: Equatable {

    var address: String
    var date: Date?
    var data: String?

    init() {
        address = ""
        data = ""
        date = Date()
    }

    init(address: String, date: Date?, data: String?) {
        (self.address, self.date, self.data) = (address, date, data)
    }

    init(confirmation: TransactionConfirmation) {
        address = confirmation.owner.address.checksummed
        date = confirmation.submissionDate
        data = confirmation.data.map { "0x" + $0.data.toHexString() }
    }

    static func == (lhs: TransactionConfirmationViewModel, rhs: TransactionConfirmationViewModel) -> Bool {
        (lhs.address, lhs.data, lhs.date) == (rhs.address, rhs.data, rhs.date)
    }

}
