//
//  AssetsView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CoinsView: View {
    @ObservedObject
    var model: CoinsViewModel

    init(safe: Safe) {
        self.model = CoinsViewModel(safe: safe)
    }

    var body: some View {
        ZStack(alignment: .center) {
            if model.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            } else if model.errorMessage != nil {
                ErrorText(model.errorMessage!)
            } else {
                balances
            }
        }
    }

    var balances: some View {
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
            if tokenBalance.address != nil {
                TokenImage(imageURL: tokenBalance.imageURL!)
            } else {
                EtherImage()
            }
            BoldText(tokenBalance.symbol)
            Spacer()
            VStack(alignment: .trailing) {
                BoldText(tokenBalance.balance)
                FootnoteText(tokenBalance.balanceUsd)
            }
        }
        .frame(height: 58)
    }
}
