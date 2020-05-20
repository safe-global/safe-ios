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
        NavigationLink(destination: EnterSafeAddressView(){
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack(spacing: 6) {
                Image.plusCircle

                Text("Add Safe").font(Font.gnoBody.weight(.medium))

                Spacer()
            }
            .frame(height: 45)
            .foregroundColor(.gnoHold)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
