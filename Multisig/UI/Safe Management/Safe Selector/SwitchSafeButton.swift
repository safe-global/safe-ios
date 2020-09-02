//
//  SwitchSafeButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SwitchSafeButton: View {
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selected: FetchedResults<Safe>

    var body: some View {
        ZStack {
            if selected.first == nil {
                EmptyView()
            } else {
                Button(action: {
                    App.shared.viewState.showsSafesList = true
                }) {
                    Image.chevronDownCircle
                }
                .frameForTapping(alignment: .trailing)
            }
        }
    }
}

struct SwitchSafeButton_Previews: PreviewProvider {
    static var previews: some View {
        SwitchSafeButton()
    }
}
