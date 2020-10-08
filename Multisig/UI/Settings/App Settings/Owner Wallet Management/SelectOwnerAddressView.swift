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
    
    private var rootNode: HDNode?
    var onSubmit: (() -> Void)?
    
    @State
    private var addresses = [Address]()

    @State
    private var selected = 0

    private var maxAddressesCount = 100
    private var pageSize = 20

    init(rootNode: HDNode?, onSubmit: (() -> Void)? = nil ) {
        self.rootNode = rootNode
        let addresses: [Address] = generateAddressesPage()
        _addresses = State(initialValue: addresses)
        self.onSubmit = onSubmit
    }

    private func addressAt(_ index: Int) -> Address? {
        guard let pkData = rootNode?.derive(index: UInt32(index), derivePrivateKey: true)?.privateKey else {
            return nil
        }
        let address = try! EthereumPrivateKey(hexPrivateKey: pkData.toHexString()).address
        return Address(address, index: index)
    }

    var body: some View {
        VStack {
            List {
                headerView
                ForEach(addresses) { address in
                    self.addressView(address)
                }
                if addresses.count < maxAddressesCount {
                    showMoreView
                }
            }
        }
        .navigationBarTitle("Import Wallet", displayMode: .inline)
        .navigationBarItems(trailing: importButton)
    }

    private var importButton: some View {
        Button("Import", action: importWallet)
            .barButton()
    }

    private func importWallet() {
        guard let pkData = rootNode?.derive(index: UInt32(selected),
                                            derivePrivateKey: true)?.privateKey else { return }
        do {
            try App.shared.keychainService.save(data: pkData, forKey: KeychainKey.ownerPrivateKey.rawValue)
            App.shared.snackbar.show(message: "Owner key successfully imported")
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
        }
        AppSettings.setSigningKeyAddress(addresses[selected].checksummed)
        // not needed in iOS less than 14
        if #available(iOS 14.0, *) {
            self.presentationMode.wrappedValue.dismiss()
        } else {
            onSubmit?()
        }
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
            self.selected = address.index
        }) {
            HStack(spacing: 12) {
                Text("#\(address.index)")
                    .frame(minWidth: 24)
                AddressView(address)
                if address.index == selected {
                    Image.checkmark.frame(width: 24)
                } else {
                    Spacer().frame(width: 24)
                }
            }
        }
    }

    private var showMoreView: some View {
        Button("Show more", action: showMore)
            .foregroundColor(.gnoHold)
            .font(Font.body.bold())
            .padding()
            .frame(maxWidth: .infinity)
    }

    private func showMore() {
        addresses += generateAddressesPage()
    }

    private func generateAddressesPage() -> [Address] {
        return (1...pageSize).compactMap { addressAt($0 + addresses.count) }
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
