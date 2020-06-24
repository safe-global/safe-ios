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

    var model = TransactionsViewModel()

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
                Loadable(TransactionListView(model: model))
            }
        }
        .onReceive(selectedSafe.publisher) { safe in
            // instead of re-creating the model, we re-assign the safe
            // when it changes, because the body of this view is redrawn,
            // and that is causing the unneeded reloading of the
            // network request.
            self.model.safe = safe
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
