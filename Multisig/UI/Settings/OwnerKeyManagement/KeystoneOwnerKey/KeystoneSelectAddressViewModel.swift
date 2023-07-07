//
//  KeystoneSelectAddressViewModel.swift
//  Multisig
//
//  Created by Zhiying Fan on 17/9/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import URRegistry
import SafeWeb3

final class KeystoneSelectAddressViewModel: SelectOwnerAddressViewModelProtocol {
    var items = [KeyAddressInfo]()
    var selectedIndex = 0
    var pageSize = 20
    
    var selectedPrivateKey: PrivateKey?
    
    var selectedKeystoneKeyParameters: AddKeystoneKeyParameters? {
        guard
            let hexPublicKey = hexPublicKey(selectedIndex),
            let publicKey = try? EthereumPublicKey(hexPublicKey: hexPublicKey)
        else { return nil }
        return AddKeystoneKeyParameters(address: Address(publicKey.address),
                                        derivationPath: derivationPath(at: selectedIndex),
                                        sourceFingerprint: hdKey?.sourceFingerprint ?? hdKeys?.first?.sourceFingerprint)
    }
    
    var canLoadMoreAddresses: Bool {
        items.count < maxItemCount
    }
    
    var maxItemCount = 100
    private var hdKey: CryptoHDKey?
    private var hdKeys: [CryptoHDKey]?
    
    init(hdKey: CryptoHDKey) {
        self.hdKey = hdKey
        generateNextPage()
        selectedIndex = items.first?.exists == true ? -1 : 0
    }
    
    init(hdKeys: [CryptoHDKey]) {
        self.hdKeys = hdKeys
        maxItemCount = hdKeys.count
        generateNextPage()
        selectedIndex = items.first?.exists == true ? -1 : 0
    }
    
    func generateNextPage() {
        do {
            let indexes = (items.count..<items.count + min(pageSize, maxItemCount))
            let addresses = indexes.map(publicAddressAt)
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
    
    private func hexPublicKey(_ index: Int) -> String? {
        guard index >= 0 else { return nil }
        
        if let hdKeys = hdKeys, index < hdKeys.count {
            return URRegistry.shared.getUncompressedKey(from: hdKeys[index].key)
        } else {
            guard let hdKey = hdKey, let chainCode = hdKey.chainCode else { return nil }
            
            let hdNode = HDNode()
            hdNode.publicKey = Data(hex: hdKey.key)
            hdNode.chaincode = Data(hex: chainCode)
            
            if let publicKeyData = hdNode.derive(path: path(at: index), derivePrivateKey: false)?.publicKey,
               let uncompressedKey = URRegistry.shared.getUncompressedKey(from: publicKeyData.toHexString()) {
                return uncompressedKey
            } else {
                return nil
            }
        }
    }
    
    private func derivationPath(at index: Int) -> String {
        if hdKey != nil  {
            return "\(HDNode.defaultPathPrefix)/\(path(at: index))"
        } else {
            return "m/44'/60'/\(index)'/0/0"
        }
    }
    
    private func path(at index: Int) -> String {
        return hdKey?.note == .ledgerLegacy ? "\(index)" : "0/\(index)"
    }
}
