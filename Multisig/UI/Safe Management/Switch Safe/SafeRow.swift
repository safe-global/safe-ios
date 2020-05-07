//
//  SafeRow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeRow: View {

    @ObservedObject
    var safe: Safe

    var onTap: () -> Void = {}

    var body: some View {
        Button(action: {
            self.safe.select()
            self.onTap()
        }) {
            HStack {
                SafeCell(safe: safe)

                Spacer()

                if safe.isSelected {
                    Image(systemName: "checkmark")
                        .font(Font.body.weight(.semibold))
                        .foregroundColor(.gnoHold)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .frame(height: 55)
    }
}
