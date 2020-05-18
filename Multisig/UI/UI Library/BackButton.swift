//
//  BackButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BackButton: View {

    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    var label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left").font(.system(size: 25))
            Text(label)
        }
        // this makes the chevron position identical to system chevron position
        .offset(x: -7)
    }
}

struct BackButton_Previews: PreviewProvider {
    static var previews: some View {
        BackButton("Cancel")
    }
}
