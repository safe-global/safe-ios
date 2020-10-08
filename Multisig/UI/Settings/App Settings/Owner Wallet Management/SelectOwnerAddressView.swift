//
//  SelectOwnerAddressView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 09.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Web3

struct SelectOwnerAddressView: View {
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @ObservedObject
    var model: SelectOwnerAddressViewModel
    
    private var onSubmit: (() -> Void)?
    
    init(rootNode: HDNode?, onSubmit: (() -> Void)? = nil ) {
        model = SelectOwnerAddressViewModel(rootNode: rootNode)
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack {
            List {
                headerView
                ForEach(model.addresses) { address in
                    self.addressView(address)
                }
                if model.canLoadMoreAddresses {
                    showMoreView
                }
            }
        }
        .navigationBarTitle("Import Wallet", displayMode: .inline)
        .navigationBarItems(trailing: importButton)
    }

    private var importButton: some View {
        Button("Import", action: submit)
            .barButton()
    }

    private var headerView: some View {
        VStack(spacing: 24) {
            Text("Select account")
                .headline()
            Text("Derived accounts are generated from your account. Select an account you would like to connect")
                .body()
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func addressView(_ address: Address) -> some View {
        Button(action: {
            model.selectedIndex = address.index
        }) {
            HStack(spacing: 12) {
                Text("#\(address.index + 1)")
                    .frame(minWidth: 24)
                AddressView(address)
                if address.index == model.selectedIndex {
                    Image.checkmark.frame(width: 24)
                } else {
                    Spacer().frame(width: 24)
                }
            }
        }
    }

    private var showMoreView: some View {
        Button("Show more", action: model.generateAddressesPage)
            .foregroundColor(.gnoHold)
            .font(Font.body.bold())
            .padding()
            .frame(maxWidth: .infinity)
    }

    func submit() {
        guard model.importWallet() else { return }
        //not needed in iOS less than 14
        if #available(iOS 14.0, *) {
            self.presentationMode.wrappedValue.dismiss()
        } else {
            onSubmit?()
        }
    }
}

struct SelectOwnerAddressView_Previews: PreviewProvider {
    static var previews: some View {
        let seed = Data(hex: "692e25c4924aa3f6a03791c447a48e78f0752ab4a04a3eaadeb5370da07666c971a5eb4f7313493f22dc5480a4ca85284c5280562867ef4105b7d46fe27162b1")
        let rootNode = HDNode(seed: seed)!.derive(path: HDNode.defaultPathMetamaskPrefix, derivePrivateKey: true)!

        return NavigationView {
            SelectOwnerAddressView(rootNode: rootNode)
        }
    }
}
