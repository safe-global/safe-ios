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
    var isValidating: Binding<Bool?> = .constant(nil)
    var error: Binding<String> = .constant("")
    var onEditingChanged: (Bool) -> Void = { _ in }
    var onCommit: () -> Void = { }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField(title,
                          text: text,
                          onEditingChanged: onEditingChanged,
                          onCommit: onCommit)
                    .font(.body)

                if isValidating.wrappedValue == true {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                }
            }
            .padding()
            .frame(height: 56)
            .background(borderView)

            if !error.wrappedValue.isEmpty {
                Text(error.wrappedValue).error()
            }
        }
    }

    var borderView: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(strokeColor, lineWidth: 2)
    }

    var strokeColor: Color {
        if isValid.wrappedValue == false {
            return Color.error
        } else {
            return Color.border
        }
    }

}

struct MyTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            RoundedTextField(title: "Enter name",
                        text: .constant(""),
                    isValid: .constant(false))

            Text("Error occurred").error()
        }
    }
}
