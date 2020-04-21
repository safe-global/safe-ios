//
//  AddressInput.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddressInput: View {

    @State var text: String?
    @State var valid: Bool = true
    @State var isPresented: Bool = false

    let placeholder = "Enter Safe address"

    var body: some View {
        Button(action: { self.isPresented.toggle() }) {
            InputFrame(isValid: valid) {
                if text == nil || text!.isEmpty {
                    Text(placeholder).font(.gnoCallout)
                        .padding()
                } else {
                    AddressView(text!).padding()
                }
            }

            AddressInputSourceSheet(text: $text, isPresented: $isPresented)
        }
    }

    struct InputFrame<Content>: View where Content: View {
        private var isValid: Bool
        let content: Content

        init(isValid: Bool, @ViewBuilder content: () -> Content) {
            self.isValid = isValid
            self.content = content()
        }

        var body: some View {
            HStack {
                content

                Spacer()

                Image(systemName: "ellipsis")
                    .padding()
            }
            .foregroundColor(Color.gnoMediumGrey)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isValid ? Color.gnoWhitesmoke : .gnoTomato,
                            lineWidth: 2)
            )
        }
    }

}

struct AddressInput_Previews: PreviewProvider {
    static var previews: some View {
            NavigationView {
                VStack {
                    AddressInput()
                    .padding()
                }.navigationBarTitle("Title")
        }
    }
}
