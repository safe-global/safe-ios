//
//  AddSafeRow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddSafeRow: View {

    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @State var showsAddSafe = false

    var body: some View {
        Button(action: { self.showsAddSafe.toggle() }) {
            HStack(spacing: 6) {
                Image.plusCircle

                Text("Add Safe").font(Font.gnoBody.weight(.medium))

                Spacer()

                NavigationLink(destination: EnterSafeAddressView {
                    self.presentationMode.wrappedValue.dismiss()
                }, isActive: $showsAddSafe, label: { EmptyView() })
            }
        }
        .frame(height: 45)
        .foregroundColor(.gnoHold)
    }
}
