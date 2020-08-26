//
//  EnterSafeNameView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EnterSafeNameView: View {

    @ObservedObject
    var model: EnterSafeNameViewModel
    var onSubmit: () -> Void

    init(address: String, onSubmit: @escaping () -> Void = {}) {
        model = EnterSafeNameViewModel(address: address)
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(spacing: Spacing.extraLarge) {
            CorrectAddressView(address: model.address)
                .layoutPriority(1)

            Text("Choose a name for the Safe. The name is only stored locally and will not be shared with Gnosis or any third parties.")
                .body()
                .multilineTextAlignment(.center)

            RoundedTextField(
                title: "Enter name",
                text: $model.enteredText,
                isValid: $model.isValid,
                onEditingChanged: { ended in
                    if !ended {
                        self.model.onEditing()
                    }
                },
                onCommit: { self.submit() })

            Spacer()
        }
        .padding(.top, Spacing.extraLarge)
        .padding(.horizontal)
        .keyboardAdaptive()
        .navigationBarTitle("Load Safe Multisig", displayMode: .inline)
        .navigationBarItems(trailing: nextButton)
        .onAppear {
            self.trackEvent(.safeAddName)
        }
    }

    var nextButton: some View {
        Button("Next", action: submit)
            .barButton(disabled: model.isValid != true)
    }

    func submit() {
        guard model.isValid == true else { return }
        model.submit()
        // otherwise there is a UI glitch with empty nav bar when pressing 'Next'
        // without hiding a keyboard
        UIResponder.resignCurrentFirstResponder()
        onSubmit()
    }

}

struct NameForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EnterSafeNameView(address: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F")
        }
    }
}
