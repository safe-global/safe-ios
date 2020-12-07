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
    var data: DataWithLength
    var body: some View {
        List {
            HexDataCellView(data: data)

            if hasParamters {
                ForEach(dataDecoded.parameters!) { paramter in
                    ParameterView(parameter: paramter)
                }
            } else {
                Text("No parameters").body()
            }
        }
        .navigationBarTitle(dataDecoded.method)
        .onAppear {
            self.trackEvent(.transactionsDetailsAction)
        }
    }

    var hasParamters: Bool {
        !(dataDecoded.parameters ?? []).isEmpty
    }
}

struct TransactionActionDetailsViewV2: View {
    var dataDecoded: SCG.DataDecoded
    var data: DataString?
    var body: some View {
        List {
            if let data = data {
                HexDataCellView(data: (UInt256(data.data.count), data.description))
            }

            if let params = dataDecoded.parameters {
                ForEach(0..<params.count) { index in
                    ParameterViewV2(parameter: params[index])
                }
            } else {
                Text("No parameters").body()
            }
        }
        .navigationBarTitle(dataDecoded.method)
        .onAppear {
            self.trackEvent(.transactionsDetailsAction)
        }
    }
}
