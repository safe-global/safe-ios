//
//  AssetsView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AssetsView: View {
    @ObservedObject
    var model = AssetsViewModel(address: "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")

    var body: some View {
        List {
            ForEach(model.balances) { tokenBalance in
                TokenBalanceCell(tokenBalance: tokenBalance)
            }
        }
    }
}

struct TokenBalanceCell: View {
    var tokenBalance: TokenBalance

    var body: some View {
        HStack(spacing: 12) {
            BoldText(tokenBalance.address)

            Spacer()

            VStack(alignment: .leading) {
                BoldText(tokenBalance.balance)
                BodyText(tokenBalance.balanceUsd)
            }
        }
    }
}

struct AssetsView_Previews: PreviewProvider {
    static var previews: some View {
        AssetsView()
    }
}
