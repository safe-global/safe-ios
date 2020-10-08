//
//  AssetsView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 18.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AssetsView: View {
    var body: some View {
        WithSelectedSafe(safeNotSelectedEvent: .assetsNoSafe) {
            AssetsTopTabView()
        }
        .navigationBarTitle("Assets")
    }
}

struct AssetsTopTabView: View {
    @State
    var selection: Int? = 0

    var body: some View {
        TopTabView($selection) {
            CoinBalancesView()
                .gnoTabItem(id: 0) {
                    HStack {
                        Image("ico-coins")
                        Text("COINS")
                            .caption()
                            .tracking(0.45)
                    }
                    .frame(maxWidth: .infinity)
                }
            CollectibleBalancesView()
                .gnoTabItem(id: 1) {
                    HStack {
                        Image("ico-collectibles")
                        Text("COLLECTIBLES")
                            .caption()
                            .tracking(0.45)
                    }
                }
        }
        .background(Color.gnoWhite)
    }
}

struct AssetsView_Previews: PreviewProvider {
    static var previews: some View {
        AssetsView()
    }
}
