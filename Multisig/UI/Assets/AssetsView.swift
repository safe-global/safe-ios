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

    @ObservedObject
    var viewState: ViewState = App.shared.viewState

    var body: some View {
        ZStack {
            if selectedSafe.first != nil {
                TopTabView($selection) {
                    LoadableView(BalancesView(safe: selectedSafe.first!))
                        .gnoTabItem(id: 0) {
                            HStack {
                                Image("ico-coins")
                                Text("COINS")
									.font(Font.gnoCaption1)
			                        .tracking(0.45)
                            }
                            .frame(maxWidth: .infinity)
                        }

                    VStack(spacing: 35) {
                        Text("Coming soon")
                        Button("Show") {
                            self.viewState.show(message: "Snacky snack!🍿")
                        }
                        .disabled(self.viewState.showsSnackbar)
                    }
                    .gnoTabItem(id: 1) {
                        HStack {
                            Image("ico-collectibles")
                            Text("COLLECTIBLES")
                                .font(Font.gnoCaption1)
                                .tracking(0.45)
                        }
                    }
                }
                .background(Color.gnoWhite)
            } else {
                VStack(spacing: 0) {                    
                    AddSafeIntroView().onAppear {
                        self.trackEvent(.assetsNoSafe)
                    }
                }
            }
        }
    }
}

struct AssetsView_Previews: PreviewProvider {
    static var previews: some View {
        AssetsView()
    }
}
