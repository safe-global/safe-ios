//
//  SelectedSafeButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SelectedSafeButton: View {
    @Binding
    var showsSafeInfo: Bool
    
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selected: FetchedResults<Safe>

    var body: some View {
        Button(action: { self.showsSafeInfo.toggle() }) {
            if selected.first == nil {
                notSelectedView
            } else {
                SafeCell(safe: selected.first!, iconSize: iconSize)
            }
            Spacer()
        }
        .frame(width: 170, height: 44, alignment: .leading)
        .disabled(selected.first == nil)
    }

    let iconSize: CGFloat = 36

    var notSelectedView: some View {
        HStack {
            Image("safe-selector-not-selected-icon")
                .resizable()
                .renderingMode(.original)
                .frame(width: iconSize, height: iconSize)

            Text("No Safe loaded")
                .headline(.gnoMediumGrey)
        }
    }

}
