//
//  TransactionCellView.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionCellView: View {
    let transaction: Transaction
    var body: some View {
        //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        ConfirmationCountView(currentValue: 2, maxValue: 3)
    }
}

//struct TransactionCellView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionCellView()
//    }
//}
