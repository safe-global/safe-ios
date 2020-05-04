//
//  EnterENSNameView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EnterENSNameView: View {

    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @ObservedObject
    var model = EnterENSNameViewModel()

    var onConfirm: (String) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 18) {
            RoundedTextField(title: "Enter ENS name",
                             text: $model.text,
                             isValid: $model.isValid,
                             isValidating: $model.isResolving,
                             error: $model.errorMessage)

            if model.address != nil {
                BodyText(label: "Address found")

                CorrectAddressView(address: model.address!.hex(eip55: true))
            }
            Spacer()
        }
        .padding(.top, 32)
        .padding([.leading, .trailing])
        .navigationBarTitle("Enter ENS Name", displayMode: .inline)
        .navigationBarItems(trailing: confirmButton)
        .onReceive(model.$text, perform: model.resolve(name:))
    }

    var confirmButton: some View {
        Button("Confirm") {
            self.presentationMode.wrappedValue.dismiss()
            self.onConfirm(self.model.address!.hex(eip55: true))
        }
        .disabled(model.address == nil)
    }

}

struct EnterENSNameView_Previews: PreviewProvider {
    static var previews: some View {
        EnterENSNameView()
    }
}
