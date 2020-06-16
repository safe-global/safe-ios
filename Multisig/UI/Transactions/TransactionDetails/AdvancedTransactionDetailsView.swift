//
//  AdvancedTransactionDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 5/29/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AdvancedTransactionDetailsView: View {
    let transaction: BaseTransactionViewModel
    
    var body: some View {
        Text("Hello, World!").onAppear {
            self.trackEvent(.transactionsDetailsAdvanced)
        }
    }
}
