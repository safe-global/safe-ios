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
    var model = AssetsViewModel()

    var body: some View {
        ZStack(alignment: .center) {
            if model.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            } else if model.errorMessage != nil {
                ErrorText(label: model.errorMessage!)
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
            TokenImage(imageURL: tokenBalance.imageURL)

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
