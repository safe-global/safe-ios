//
//  TokenBalanceCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TokenBalanceCell: View {
    var tokenBalance: TokenBalance

    var body: some View {
        HStack(spacing: Spacing.small) {
            if tokenBalance.address != Address.ether.checksummed {
                TokenImage(url: tokenBalance.imageURL)
            } else {
                TokenImage.ether
            }
            Text(tokenBalance.symbol).headline()
            Spacer()
            VStack(alignment: .trailing) {
                Text(tokenBalance.balance).headline()
                Text(tokenBalance.balanceUsd).footnote()
            }
        }
        .frame(height: 48)
    }
}
