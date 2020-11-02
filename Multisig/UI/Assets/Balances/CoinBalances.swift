//
//  CoinBalances.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CoinBalancesView: View {
    @EnvironmentObject
    var model: CoinBalancesModel
    var body: some View {
        NetworkContentView(status: model.status, reload: model.reload) {
            BalanceListView(total: model.total, balances: model.result, reload: model.reload)
        }
        .onAppear {
            trackEvent(.assetsCoins)
        }
    }
}

struct BalanceListView: View {
    var total: String
    var balances: [TokenBalance]
    var reload: () -> Void = {}
    var body: some View {
        List {
            ReloadButton(reload: reload)
            TotalBalanceCell(total: total)
            ForEach(balances) { tokenBalance in
                TokenBalanceCell(tokenBalance: tokenBalance)
            }
       }
        .listStyle(PlainListStyle())
    }
}

struct TotalBalanceCell: View {
    var total: String
    var body: some View {
        HStack {
            Text("Total").headline()
            Spacer()
            Text(total).headline()
        }
        .frame(height: 48)
    }
}
