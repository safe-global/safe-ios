//
//  SelectOwnerAddressViewModel.swift
//  Multisig
//
//  Created by Moaaz on 10/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3
import URRegistry

class SelectOwnerAddressViewModel: SelectOwnerAddressViewModelProtocol {
    static let notSelectedIndex = -1

    var items = [KeyAddressInfo]()
    var selectedIndex = 0

    var selectedPrivateKey: PrivateKey? {
        guard let keyData = privateKeyData(selectedIndex) else { return nil }
        return try? PrivateKey(data: keyData)
    }
    var selectedKeystoneKeyParameters: AddKeystoneKeyParameters? {
        guard
            let hexPublicKey = hexPublicKey(selectedIndex),
            let publicKey = try? EthereumPublicKey(hexPublicKey: hexPublicKey)
        else { return nil }
        return AddKeystoneKeyParameters(address: Address(publicKey.address), derivationPath: "\(HDNode.defaultPath)/\(selectedIndex)")
    }
    
    private var rootNode: HDNode?    
    var maxItemCount = 100
    var pageSize = 20

    var canLoadMoreAddresses: Bool {
        items.count < maxItemCount
    }

    init(rootNode: HDNode, onSubmit: (() -> Void)? = nil ) {
        self.rootNode = rootNode
        generateNextPage()
        selectedIndex = items.first?.exists == true ? Self.notSelectedIndex : 0
    }

    private func privateAddressAt(_ index: Int) -> Address? {
        guard let pkData = privateKeyData(index) else {
            return nil
        }

        do {
            return try PrivateKey(data: pkData).address
        } catch {
            LogService.shared.error("Could not derive address: \(error)")
            App.shared.snackbar.show(
                error: GSError.UnknownAppError(description: "Could not derive address",
                                               reason: "Unexpected error appeared.",
                                               howToFix: "Please reach out to the Safe support"))
            return nil
        }
    }

    private func publicAddressAt(_ index: Int) -> Address? {
        guard let hexPublicKey = hexPublicKey(index) else { return nil }
        
        do {
            let publicKey = try EthereumPublicKey(hexPublicKey: hexPublicKey)
            return Address(publicKey.address)
        } catch {
            LogService.shared.error("Could not derive address: \(error)")
            App.shared.snackbar.show(
                error: GSError.UnknownAppError(description: "Could not derive address",
                                               reason: "Unexpected error appeared.",
                                               howToFix: "Please reach out to the Safe support"))
            return nil
        }
    }
    
    private func privateKeyData(_ index: Int) -> Data? {
        guard index >= 0 else { return nil }
        return rootNode?.derive(index: UInt32(index), derivePrivateKey: true)?.privateKey
    }
    
    private func hexPublicKey(_ index: Int) -> String? {
        if index >= 0,
           let publicKeyData = rootNode?.derive(path: "0/\(index)", derivePrivateKey: false)?.publicKey,
           let uncompressedKey = URRegistry.shared.getUncompressedKey(from: publicKeyData.toHexString()) {
            return uncompressedKey
        } else {
            return nil
        }
    }
    
    func generateNextPage() {
        do {
            let indexes = (items.count..<items.count + pageSize)
            let hasPrivate = rootNode?.hasPrivate ?? false
            let addresses = indexes.map(hasPrivate ? privateAddressAt : publicAddressAt)
            let infoByAddress = try Dictionary(grouping: KeyInfo.keys(addresses: addresses.compactMap { $0 }), by: \.address)

            let nextPage = indexes.enumerated().compactMap { (i, addressIndex) in
                addresses[i].flatMap {
                    KeyAddressInfo(index: addressIndex, address: $0, name: infoByAddress[$0]?.first?.name)
                }
            }

            self.items += nextPage
        } catch {
            LogService.shared.error("Failed to generate addresses: \(error)")
            App.shared.snackbar.show(
                error: GSError.UnknownAppError(description: "Could not generate addresses",
                                               reason: "Unexpected error occurred.",
                                               howToFix: "Please try again later")
            )
        }
    }
}
