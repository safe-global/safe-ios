//
//  AddressInputSelector.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import UIKit

struct AddressInputSelector: View {

    var isPresented: Binding<Bool>
    var text: Binding<String>

    @State
    private var selection: InputType?

    enum InputType {
        case clipboard
        case qr
        case ens
    }

    var body: some View {
        Group {
            NavigationLink(
                destination: qrScanner,
                tag: InputType.qr,
                selection: $selection,
                label: { EmptyView() })

            //TODO: ENS Form
        }
        .actionSheet(isPresented: isPresented, content: selector)
    }

    var qrScanner: some View {
        QRCodeScanner(header: "Scan") { value in
            self.text.wrappedValue = value
        }
    }

    func selector() -> ActionSheet {
        ActionSheet(
            title: Text("Select how to enter address"),
            message: nil,
            buttons: [
                .default(Text("Paste From Clipboard")) {
                    self.selection = .clipboard
                    self.text.wrappedValue = UIPasteboard.general.string ?? ""
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

struct AddressInputSelector_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddressInputSelector(isPresented: .constant(true), text: .constant(""))
        }
    }
}

