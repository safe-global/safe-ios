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

    var body: some View {
        ZStack {
            Rectangle()
               .edgesIgnoringSafeArea(.all)
               .foregroundColor(Color.gnoWhite)
            if selectedSafe.first == nil { AddSafeIntroView() }
            else {
                EmptyListPlaceholder(label: "Transactions will appear here", image: "ico-no-transactions")
            }
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
