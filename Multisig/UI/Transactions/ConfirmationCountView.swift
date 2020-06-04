//
//  ConfirmationCountView.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ConfirmationCountView: View {
    let currentValue: Int
    let maxValue: Int
    var body: some View {
        let color = currentValue == maxValue ? Color.gnoHold : Color.gnoMediumGrey
        return HStack(spacing: 6) {
            Image("ico-confirmation-count").foregroundColor(color)
            FootnoteText("\(currentValue) out of \(maxValue)", color: color)
        }
    }
}

struct ConfirmationCountView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationCountView(currentValue: 1, maxValue: 2)
    }
}
