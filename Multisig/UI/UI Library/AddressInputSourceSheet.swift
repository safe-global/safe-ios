//
//  AddressInputSourceSheet.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import UIKit

struct AddressInputSourceSheet: View {

    private enum Source {
        case clipboard
        case qrCode
        case ensName
    }

    @Binding var text: String?
    @Binding var isPresented: Bool

    @State private var selection: Source?

    var body: some View {
        VStack {
            NavigationLink(
                destination: QRCodeScanner(header: "Scan") { self.text = $0 },
                tag: Source.qrCode,
                selection: $selection,
                label: { EmptyView() })

            NavigationLink(
                destination: ENSNameForm(text: $text),
                tag: Source.ensName,
                selection: $selection,
                label: { EmptyView() })

        }
        .actionSheet(isPresented: $isPresented) {

            ActionSheet(title: Text("Select how to enter address"),
                        message: nil,
                        buttons: [

                .default(Text("Paste From Clipboard")) {
                    self.selection = .clipboard
                    self.text = UIPasteboard.general.string
                },
                .default(Text("Scan QR Code")) {
                    self.selection = .qrCode
                },
                .default(Text("Enter ENS Name")) {
                    self.selection = .ensName
                },
                .cancel()
            ])
        }
    }
}

struct AddressInputSourceSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddressInputSourceSheet(text: .constant(nil), isPresented: .constant(true))
    }
}
