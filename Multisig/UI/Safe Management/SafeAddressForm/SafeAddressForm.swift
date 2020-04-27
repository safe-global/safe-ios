//
//  SafeAddressForm.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeAddressForm: View {

    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @ObservedObject
    var form: SafeAddressFormModel

    var body: some View {
        VStack(spacing: 23) {
            FormHeader("Enter your Safe Multisig address.")

            SafeAddressField(title: "Enter Safe address",
                             enteredText: $form.text,
                             displayText: form.displayText,
                             isAddress: $form.isAddress,
                             isValid: $form.isValid,
                             isValidating: $form.isValidating,
                             error: $form.errorMessage)

            Spacer()
        }
        .padding(.top, 27)
        .padding([.leading, .trailing])
        .navigationBarTitle("Load Safe Multisig", displayMode: .inline)
        .navigationBarItems(leading: cancelButton, trailing: nextButton)
        .onReceive(form.$text, perform: form.validate(address:))
    }

    var nextButton: some View {
        NavigationLink("Next", destination:
            SafeNameForm(form: SafeNameFormModel(address: $form.displayText.wrappedValue)) {
                self.presentationMode.wrappedValue.dismiss()
            }

        )
        .disabled(form.isValid != true)
    }

    var cancelButton: some View {
        Button("Cancel") {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct AddressForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SafeAddressForm(form: SafeAddressFormModel())
        }
    }
}
