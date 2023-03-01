//
//  KeystoneSignFlow.swift
//  Multisig
//
//  Created by Zhiying Fan on 6/9/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import URRegistry
import Web3

final class KeystoneSignFlow: UIFlow {
    var signCompletion: ((_ unmarshaledSignature: SECP256K1.UnmarshaledSignature) -> Void)?
    
    private let signInfo: KeystoneSignInfo
    private let signRequest: KeystoneSignRequest
    
    init?(signInfo: KeystoneSignInfo, completion: @escaping (Bool) -> Void) {
        guard let signRequest = signInfo.signRequest else { return nil }
        self.signInfo = signInfo
        self.signRequest = signRequest
        super.init(completion: completion)
    }
    
    override func start() {
        requestSignature()
    }
    
    private func requestSignature() {
        URRegistry.shared.setSignRequestUREncoder(with: signRequest)
        let signVC = UIHostingController(rootView: KeystoneRequestSignatureView(onTap: { [weak self] in
            self?.presentScanner()
        }))
        signVC.navigationItem.title = "Request signature"
        
        let ribbon = ViewControllerFactory.ribbonWith(viewController: signVC)
        ribbon.storedChain = signInfo.chain
        
        show(ribbon)
    }
    
    private func presentScanner() {
        let vc = QRCodeScannerViewController()
        
        let string = "Scan the QR code on the Keystone wallet to confirm the transaction." as NSString
        let textStyle = GNOTextStyle.bodyPrimary.color(.white)
        let highlightStyle = textStyle.weight(.bold)
        let label = NSMutableAttributedString(string: string as String, attributes: textStyle.attributes)
        label.setAttributes(highlightStyle.attributes, range: string.range(of: "confirm the transaction"))
        vc.attributedLabel = label
        
        vc.scannedValueValidator = { value in
            guard value.starts(with: "UR:ETH-SIGNATURE") else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
            return .success(value)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        
        navigationController.present(vc, animated: true)
    }
}

extension KeystoneSignFlow: QRCodeScannerViewControllerDelegate {
 func scannerViewControllerDidScan(_ code: String) {
     guard
         let signature = URRegistry.shared.getSignature(from: code),
         let unmarshaledSignature = SECP256K1.UnmarshaledSignature(
            keystoneSignature: signature.signature,
            isLegacyTx: signInfo.signType == .transaction,
            chainId: signInfo.chain?.id ?? "0")
        else {
            stop(success: false)
            return
        }
        
        signCompletion?(unmarshaledSignature)
        stop(success: true)
    }
    
    func scannerViewControllerDidCancel() {
        stop(success: false)
    }
}

extension SECP256K1.UnmarshaledSignature {
    var safeSignature: String {
        let signature = r + s + Data([v + 4])
        return signature.toHexString()
    }

    init?(keystoneSignature signature: String, isLegacyTx: Bool, chainId: String) {
        let data = Data(hex: signature)
        guard data.count >= 65 else { return nil }

        let r = data[0..<32]
        let s = data[32..<64]
        let v: UInt8

        // only if v was overflown and is legacy transaction
        if isLegacyTx && data.count > 65 {

            // max 8 bytes to fit into UInt64
            let vBytes: Bytes = [UInt8](data.suffix(from: 64).prefix(8))
            let vInt =  UInt64(vBytes)
            let chainIdInt = UInt64(chainId) ?? 0

            // recover V by deducting (chainId * 2 + 35) according to EIP-155.
            let vRecovered = vInt - (chainIdInt * 2 + 35)
            v = try! UInt8(vRecovered % 256)
        } else {
            v = data[64]
        }
        assert(v == 0 || v == 1)

        self.init(v: v, r: r, s: s)
    }
}
