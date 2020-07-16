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

    var customMode: Binding<PresentationMode>?

    var label: String

    init(_ label: String) {
        self.label = label
    }

    init(_ label: String, presentationMode: Binding<PresentationMode>) {
        self.label = label
        self.customMode = presentationMode
    }

    var body: some View {
        Button(action: {
            if self.customMode == nil {
                self.presentationMode.wrappedValue.dismiss()
            } else {
                self.customMode!.wrappedValue.dismiss()
            }
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
