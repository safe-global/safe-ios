//
//  CreationTransactionBodyView.swift
//  Multisig
//
//  Created by Moaaz on 8/12/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CreationTransactionBodyView: View {
    var transaction: CreationTransactionViewModel
    private let padding: CGFloat = 11

    var body: some View {
        Group {
            TransactionStatusTypeView(transaction: transaction)

            if transaction.hash != nil {
                KeyValueRow("Transaction hash", value: transaction.hash!, enableCopy: true, color: .gnoDarkGrey).padding(.vertical, padding)
            }

            VStack (alignment: .leading, spacing: padding) {
                Text("Creator address")
                    .body()
                if transaction.creator == nil {
                    Text("Not available").body(.gnoDarkGrey)
                } else {
                    AddressCell(address: transaction.creator!)
                }
            }

            VStack (alignment: .leading, spacing: padding) {
                Text("Mastercopy used")
                    .body()
                if transaction.implementationUsed == nil {
                    Text("Not available").body(.gnoDarkGrey)
                } else {
                    AddressCell(address: transaction.implementationUsed!,
                    title: transaction.contractVersion!,
                    style: .shortAddress)
                }
            }

            VStack (alignment: .leading, spacing: padding) {
                Text("Factory used")
                    .body()
                if transaction.factoryUsed == nil {
                    Text("No factory used").body(.gnoDarkGrey)
                } else {
                    AddressCell(address: transaction.factoryUsed!)
                }
            }

            KeyValueRow("Created", value: transaction.formattedDate, enableCopy: false, color: .gnoDarkGrey).padding(.vertical, padding)
        }
    }
}

