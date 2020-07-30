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
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)

            if model.address != nil {
                CorrectAddressView(
                    title: "Address found",
                    address: model.address!.checksummed,
                    checkmarkPosition: .title)
            }
            Spacer()
        }
        .padding(.top, 32)
        .padding(.horizontal)
        .keyboardAdaptive()
        .navigationBarTitle("Enter ENS Name", displayMode: .inline)
        .navigationBarItems(trailing: confirmButton)
        .onReceive(model.$text, perform: model.resolve(name:))
        .onAppear {
            self.trackEvent(.safeAddEns)
        }
    }

    var confirmButton: some View {
        Button("Confirm") {
            self.presentationMode.wrappedValue.dismiss()
            self.onConfirm(self.model.address!.checksummed)
        }
        .barButton(disabled: model.address == nil)
    }
}

struct EnterENSNameView_Previews: PreviewProvider {
    static var previews: some View {
        EnterENSNameView()
    }
}
