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

    @ViewBuilder
    var body: some View {
        NavigationLink(destination: TransactionActionDetailsView(dataDecoded: dataDecoded)) {
            Text("Action (\(dataDecoded.method))").body()
        }
    }
}
