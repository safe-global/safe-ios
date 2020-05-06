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
        VStack(spacing: 24) {
            Group {
                CorrectAddressView(address: model.address)

                BodyText(label: "Choose a name for the Safe. The name is only stored locally and will not be shared with Gnosis or any third parties.")
                    .multilineTextAlignment(.center)
            }
            .padding([.leading, .trailing])

            RoundedTextField(title: "Enter name",
                        text: $model.enteredText,
                        isValid: $model.isValid,
                        onEditingChanged: { ended in
                            if !ended {
                                self.model.onEditing()
                            }
                        },
                        onCommit: submit)

            Spacer()
        }
        .padding(.top, 24)
        .padding([.leading, .trailing])
        .navigationBarTitle("Load Safe Multisig", displayMode: .inline)
        .navigationBarItems(trailing: nextButton)
    }

    var nextButton: some View {
        Button("Next", action: submit)
            .disabled(model.isValid != true)
    }

    func submit() {
        guard model.isValid == true else { return }
        model.submit()
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
