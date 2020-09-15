//
//  SafeAddressInput.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// needs to be inside a navigation view (eventually) in order for
// input selector to open the QR scanner and ENS name form on the
// next screen.
struct SafeAddressField: View {

    // rendered when text is empty
    var title: String

    // The text entered through the field.
    //
    // when not empty, renders in the field according to the "isAddress" logic
    // and "title" logic
    //
    // when empty, shows the "create safe" prompt under the field
    //
    // note: using the `Binding<String>` instead of `@Binding var` here
    // because the binding is injected from the outside. The @Binding
    // does not give an option to inject it from the outside.
    var enteredText: Binding<String>

    // The text that will be displayed
    var displayText: String

    // has effect when the text is not empty
    // true - renders text as address with identicon
    // false - renders text as text
    var isAddress: Binding<Bool>

    // nil - validation not finished
    // true - valid
    // false - invalid
    var isValid: Binding<Bool?>

    // true - shows progress indicator
    // false - shows "more" button
    var isValidating: Binding<Bool>

    // when not empty, shows error under the text
    var error: Binding<String>

    var isEmpty: Bool { displayText.isEmpty }

    @State
    private var showsSelector: Bool = false

    enum InputType {
        case clipboard
        case qr
        case ens
    }

    @State
    private var selection: InputType? {
        didSet {
            showsQR = selection == .qr
        }
    }

    @State
    private var showsQR = false

    var body: some View {
        VStack(spacing: 15) {
            VStack(alignment: .leading) {
                inputView
                errorView
            }
            if isEmpty {
                CreateSafePrompt()
            }
        }
    }

    // the properties are wrapped into "Group" in order to
    // conform to the opaque type requirement (always return the same
    // concrete type)
    var errorView: some View {
        ZStack {
            if !error.wrappedValue.isEmpty {
                Text(error.wrappedValue).error()
            }
        }
    }

    var inputView: some View {
        Button(action: { self.showsSelector.toggle() }) {
            HStack {
                contentView

                Spacer()

                rightView

                NavigationLink(
                    destination: EnterENSNameView(onConfirm: setText(_:)),
                    tag: InputType.ens,
                    selection: $selection,
                    label: { EmptyView() }
                )
                    // otherwise the "pop to root" stops working
                    .isDetailLink(false)
            }
        }
        .font(.gnoBody)
        .padding()
        .frame(height: isEmpty ? 56 : 74)
        .background(borderView)
        .foregroundColor(.gnoMediumGrey)
        .actionSheet(isPresented: $showsSelector, content: selector)
        .sheet(isPresented: $showsQR) {
            QRCodeScanner(handler: self.setText(_:))
                .edgesIgnoringSafeArea(.all)
        }
    }

    func setText(_ value: String) {
        enteredText.wrappedValue = value
    }

    var contentView: some View {
        ZStack {
            if isEmpty {
                Text(title)
            } else if isAddress.wrappedValue {
                AddressView(displayText)
            } else {
                Text(displayText).foregroundColor(Color.gnoDarkBlue)
            }
        }
    }

    var rightView: some View {
        ZStack {
            if isValidating.wrappedValue {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            } else {
                Image.ellipsis
            }
        }
    }

    var borderView: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(strokeColor, lineWidth: 2)
    }

    var strokeColor: Color {
        if isValid.wrappedValue == false {
            return Color.gnoTomato
        } else {
            return Color.gnoWhitesmoke
        }
    }

    func selector() -> ActionSheet {
        ActionSheet(
            title: Text("Select how to enter address"),
            message: nil,
            buttons: [
                .default(Text("Paste From Clipboard")) {
                    self.selection = .clipboard
                    self.setText(Pasteboard.string ?? "")
                },
                .default(Text("Scan QR Code")) {
                    self.selection = .qr
                },
                .default(Text("Enter ENS Name")) {
                    self.selection = .ens
                },
                .cancel()
        ])
    }
}

struct SafeAddressInput_Previews: PreviewProvider {
    static var previews: some View {

        NavigationView {
            SafeAddressField(title: "Enter Safe address",
                             enteredText: .constant(""),
                             displayText: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F",
                             isAddress: .constant(true),
                             isValid: .constant(nil),
                             isValidating: .constant(false),
                             error: .constant("Safe not found."))
                .padding()
        }
    }
}
