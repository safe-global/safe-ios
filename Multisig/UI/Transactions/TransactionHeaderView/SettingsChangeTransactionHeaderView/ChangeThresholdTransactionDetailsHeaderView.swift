//
//  ChangeThresholdTransactionDetailsHeaderView.swift
//  Multisig
//
//  Created by Moaaz on 6/17/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ChangeThresholdTransactionDetailsHeaderView: View {
    var threshold: UInt64
    var body: some View {
        KeyValueRow("Change required confirmations:", value: "\(threshold)", enableCopy: false, color: Color.gnoDarkGrey)
    }
}

struct ChangeThresholdTransactionDetailsHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeThresholdTransactionDetailsHeaderView(threshold: 1)
    }
}
