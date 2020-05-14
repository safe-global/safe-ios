//
//  AddSafeRow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddSafeRow: View {

    @State var showsAddSafe = false

    var body: some View {
        Button(action: { self.showsAddSafe.toggle() }) {
            HStack(spacing: 6) {
                Image.plusCircle

                Text("Add Safe").font(Font.gnoBody.weight(.medium))

                Spacer()
            }
        }
        .frame(height: 45)
        .foregroundColor(.gnoHold)
        .sheet(isPresented: self.$showsAddSafe) {
            NavigationView {
                EnterSafeAddressView()
            }
        }
    }
}
