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
    @Binding
    var rootIsActive: Bool

    private var rootNode: HDNode?

    @State
    private var addresses = [Address]()

    @State
    private var selected = 0

    init(rootNode: HDNode?, rootIsActive: Binding<Bool>) {
        self.rootNode = rootNode
        _rootIsActive = rootIsActive
        let addresses: [Address] = (0..<20).compactMap { self.addressAt($0) }
        _addresses = State(initialValue: addresses)

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
            headerView
            List {
                ForEach(addresses) { address in
                    self.addressView(address)
                }
                showMoreView
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
        rootIsActive = false
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
        addresses += (addresses.count..<addresses.count + 20).compactMap { addressAt($0) }
    }
}

struct SelectOwnerAddressView_Previews: PreviewProvider {
    static var previews: some View {
        let seed = Data(hex: "692e25c4924aa3f6a03791c447a48e78f0752ab4a04a3eaadeb5370da07666c971a5eb4f7313493f22dc5480a4ca85284c5280562867ef4105b7d46fe27162b1")
        let rootNode = HDNode(seed: seed)!.derive(path: HDNode.defaultPathMetamaskPrefix, derivePrivateKey: true)!

        return NavigationView {
            SelectOwnerAddressView(rootNode: rootNode, rootIsActive: .constant(true))
        }
    }
}
