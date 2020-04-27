//
//  MyTextField.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct RoundedTextField: View {

    var title: String
    var text: Binding<String>
    var isValid: Binding<Bool?>
    var onEditingChanged: (Bool) -> Void = { _ in }
    var onCommit: () -> Void = { }

    var body: some View {
        HStack {
            TextField(title,
                      text: text,
                      onEditingChanged: onEditingChanged,
                      onCommit: onCommit)

            rightView

        }
        .frame(height: 56)
        .padding([.leading, .trailing])
        .background(borderView)
    }

    var borderView: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(strokeColor, lineWidth: 2)
    }

    var strokeColor: Color {
        if isValid.wrappedValue == true {
            return Color.gnoHold50
        } else if isValid.wrappedValue == false {
            return Color.gnoTomato
        } else {
            return Color.gnoWhitesmoke
        }
    }

    var rightView: some View {
        Group {
            if isValid.wrappedValue == true {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.gnoHold)
            } else if isValid.wrappedValue == false {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.gnoTomato)
            } else {
                EmptyView()
            }
        }
    }

}

struct MyTextField_Previews: PreviewProvider {
    static var previews: some View {
        RoundedTextField(title: "Enter name",
                    text: .constant(""),
                    isValid: .constant(false))
    }
}
