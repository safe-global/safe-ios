//
//  EnterSeedPhrase.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EnterSeedPhrase: View {
    @State var seed = ""
    @State var isEditing = false
    @State var isValid = true
    @State var errorMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter your seed phrase")
                .headline()
            Text("Import the seed phrase (12 or 24 words) from your hardware or MetaMask owner wallet to sign transactions")
                .body()
                .multilineTextAlignment(.center)
            EnterSeedView(seed: $seed, isEditing: $isEditing, isValid: $isValid, errorMessage: $errorMessage)
            Spacer()
        }
        .padding()
        .navigationBarTitle("Import Wallet", displayMode: .inline)
        .navigationBarItems(trailing: nextButton)
    }

    var nextButton: some View {
        Button("Next", action: submit)
            .barButton()
    }

    // TODO: handle return button on the keyboard
    func submit() {
        guard let seedData = BIP39.seedFromMmemonics(seed),
            let rootNode = HDNode(seed: seedData)?.derive(path: HDNode.defaultPathMetamaskPrefix,
                                                          derivePrivateKey: true) else {
            isValid = false
            errorMessage = "Seed phrase is not valid"
            return
        }
        // TODO: pass rootNode to the next screen
    }
}

struct EnterSeedView: View {
    @Binding var seed: String
    @Binding var isEditing: Bool
    @Binding var isValid: Bool
    @Binding var errorMessage: String

    var body: some View {
        VStack(alignment: .leading) {
            TextView(text: $seed,
                     isEditing: $isEditing,
                     placeholder: "Enter seed phrase",
                     textHorizontalPadding: 12,
                     textVerticalPadding: 16,
                     placeholderHorizontalPadding: 16,
                     placeholderVerticalPadding: 16,
                     shouldChange: shouldChange)
                .frame(height: 120)
                .background(borderView)

            Text(errorMessage).error()
        }
    }

    private func shouldChange(in range: NSRange, with value: String) -> Bool {
        isValid = true
        errorMessage = ""
        return true
    }

    var borderView: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(strokeColor, lineWidth: 2)
    }

    var strokeColor: Color {
        isValid ? Color.gnoWhitesmoke : Color.gnoTomato
    }
}

struct EnterSeedPhrase_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EnterSeedPhrase()
        }
    }
}
