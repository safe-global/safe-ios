//
//  ActionDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 8/20/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionActionDetailsView: View {
    var dataDecoded: DataDecoded
    var body: some View {
        List {
            if hasParamters {
                ForEach(dataDecoded.parameters!, id: \.name) { paramter in
                    ParameterView(parameter: paramter)
                }
            } else {
                Text("No parameters").body()
            }
        }
        .navigationBarTitle(dataDecoded.method)
    }

    var hasParamters: Bool {
        !(dataDecoded.parameters ?? []).isEmpty
    }
}
