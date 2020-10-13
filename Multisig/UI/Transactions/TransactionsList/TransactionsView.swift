//
//  TransactionsView.swift
//  Multisig
//
//  Created by Moaaz on 5/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionsView: View {
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>

    @ObservedObject
    var viewState = App.shared.viewState

    @ObservedObject
    var appSettings = App.shared.settings

    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .edgesIgnoringSafeArea(.all)
                .foregroundColor(Color.gnoWhite)

            if selectedSafe.first == nil {
                AddSafeIntroView().onAppear {
                    self.trackEvent(.transactionsNoSafe)
                }
            } else {
                LoadableView(TransactionListView(safe: selectedSafe.first!))
            }
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
