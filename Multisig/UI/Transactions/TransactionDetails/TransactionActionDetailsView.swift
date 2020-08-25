//
//  ActionDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 8/20/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionActionDetailsView: View {
    var dataDecoded: TransactionData
    var body: some View {
        List {
            ForEach(dataDecoded.parameters, id: \.name) { paramter in
                ParameterView(parameter: paramter)
            }
        }
        .navigationBarTitle(dataDecoded.method)
    }
}
