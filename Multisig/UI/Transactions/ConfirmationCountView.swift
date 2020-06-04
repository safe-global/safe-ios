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
    let threshold: Int
    var body: some View {
        let color = currentValue >= threshold ? Color.gnoHold : Color.gnoMediumGrey
        return HStack(spacing: 6) {
            Image("ico-confirmation-count").foregroundColor(color)
            FootnoteText("\(currentValue) out of \(threshold)", color: color)
        }
    }
}

struct ConfirmationCountView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationCountView(currentValue: 1, threshold: 2)
    }
}
