//
//  ConfirmationCountView.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ConfirmationCountView: View {
    let currentValue: UInt64
    let threshold: UInt64

    var color: Color {
        currentValue >= threshold ? Color.gnoHold : Color.gnoMediumGrey
    }
    var body: some View {
        HStack(spacing: 6) {
            Image("ico-confirmation-count").foregroundColor(color)

            Text("\(currentValue) out of \(threshold)")
                .footnote(color)
        }
    }
}

struct ConfirmationCountView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationCountView(currentValue: 1, threshold: 2)
    }
}
