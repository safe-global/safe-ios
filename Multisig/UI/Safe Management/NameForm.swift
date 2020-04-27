//
//  SafeNameForm.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeNameForm: View {

    var address: String

    @ObservedObject
    var form: NameFormModel

    var body: some View {
        VStack(spacing: 24) {
            Group {
                CorrectAddressView(address: address)

                BodyText(label: "Choose a name for the Safe. The name is only stored locally and will not be shared with Gnosis or any third parties.")
                    .multilineTextAlignment(.center)
            }
            .padding([.leading, .trailing])

            RoundedTextField(title: "Enter name",
                        text: $form.enteredText,
                        isValid: $form.isValid,
                        onEditingChanged: { ended in
                            if !ended {
                                self.form.onEditing()
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
            .disabled(form.isValid != true)
    }

    func submit() {
        guard form.isValid == true else { return }

        // dismissing via presentation mode  goes back one screen
    }
}

struct NameForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SafeNameForm(address: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F",
                     form: NameFormModel())
        }
    }
}
