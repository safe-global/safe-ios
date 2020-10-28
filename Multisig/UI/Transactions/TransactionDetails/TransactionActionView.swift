//
//  ActionView.swift
//  Multisig
//
//  Created by Moaaz on 8/20/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionActionView: View {
    var dataDecoded: DataDecoded
    var data: DataWithLength

    @ViewBuilder
    var body: some View {
        NavigationLink(destination: TransactionActionDetailsView(dataDecoded: dataDecoded, data: data)) {
            Text("Action (\(dataDecoded.method))").body()
        }
    }
}
