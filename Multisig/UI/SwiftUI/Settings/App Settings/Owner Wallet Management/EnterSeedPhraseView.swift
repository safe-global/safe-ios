//
//  EnterSeedPhrase.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EnterSeedPhraseView: View {
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @State
    var seed = ""

    @State
    var isEditing = false

    @State
    var isValid = true

    @State
    var errorMessage = ""

    @State
    var rootNode: HDNode?

    @State
    var goNext = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter your seed phrase")
                .headline()
            Text("Enter the seed phrase from your hardware wallet or MetaMask owner wallet. Typically 12 (sometimes 24) words separated by single spaces. ")
                .body()
                .multilineTextAlignment(.center)
            // Otherwise keyboardAdaptive modefier behaives strangly
            // Horizontal padding if less than 12 keyboardAdaptive won't work
            HStack {
                EnterSeedView(seed: $seed, isEditing: $isEditing, isValid: $isValid, errorMessage: $errorMessage)
            }
            .padding(.horizontal, 12)

            Spacer()

//            NavigationLink(destination: SelectOwnerAddressView(
//                            rootNode: rootNode, onSubmit: {
//                                NotificationCenter.default.post(name: .ownerKeyImported, object: nil)
//                                App.shared.viewState.showImportKeySheet.toggle()
//                            }),
//                           isActive: $goNext,
//                           label: { EmptyView() })
        }
        .padding()
        .keyboardAdaptive()
        .navigationBarTitle("Import Owner Key", displayMode: .inline)
        .navigationBarItems(trailing: nextButton)
        .onAppear {
            self.trackEvent(.ownerEnterSeed)
        }
    }

    var nextButton: some View {
        Button("Next", action: submit)
            .barButton()
            .disabled(seed.isEmpty)
    }

    // TODO: handle return button on the keyboard
    func submit() {
        UIResponder.resignCurrentFirstResponder()
        guard let seedData = BIP39.seedFromMmemonics(seed),
            let rootNode = HDNode(seed: seedData)?.derive(path: HDNode.defaultPathMetamaskPrefix,
                                                          derivePrivateKey: true) else {
            isValid = false
            errorMessage = GSError.WrongSeedPhrase().localizedDescription
            return
        }
        self.rootNode = rootNode
        self.goNext = true
    }
}

struct EnterSeedView: View {
    @Binding
    var seed: String

    @Binding
    var isEditing: Bool

    @Binding
    var isValid: Bool

    @Binding
    var errorMessage: String

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

            Text(errorMessage).error().frame(maxHeight: .infinity)
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
            EnterSeedPhraseView()
        }
    }
}
