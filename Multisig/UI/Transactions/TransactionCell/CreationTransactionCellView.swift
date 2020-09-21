//
//  SettingsTransactionCellView.swift
//  Multisig
//
//  Created by Moaaz on 6/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CreationTransactionCellView: View {
    let transaction: CreationTransactionViewModel
    var body: some View {
        contentView
    }

    var contentView: some View {
        HStack {
            Image("ico-settings-tx")
            Text("Safe created").body()
            Spacer()
        }
    }
}
