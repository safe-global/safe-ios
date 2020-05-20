//
//  AssetsView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 18.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AssetsView: View {
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>

    @State var selection: Int? = 0

    var body: some View {
        TopTabView($selection) {
            ZStack {
                if selectedSafe.first != nil {
                    BalancesView(safe: selectedSafe.first!)
                } else {
                    AddSafeIntroView()
                }
            }
            .gnoTabItem(id: 0) {
                HStack {
                    Image("ico-coins")
                    Text("COINS").font(Font.gnoCaption1)
                }
                .frame(maxWidth: .infinity)
            }

            Text("Coming soon")
                .gnoTabItem(id: 1) {
                    HStack {
                        Image("ico-collectibles")
                        Text("COLLECTIBLES").font(Font.gnoCaption1)
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
