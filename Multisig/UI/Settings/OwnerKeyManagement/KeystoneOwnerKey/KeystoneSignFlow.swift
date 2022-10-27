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
    
    private func getUnmarshalSignature(signature: String) -> SECP256K1.UnmarshaledSignature? {
        let signatureData = Data(hex: signature)
        guard signatureData.count >= 65 else { return nil }
        
        let r = signatureData[0..<32]
        let s = signatureData[32..<64]
        var v = signatureData[64...][0]
        
        if signInfo.signType == .transaction {
            v = v - 35 - (UInt8(signInfo.chain?.id ?? "0") ?? 0) * 2
        }
        
        return SECP256K1.UnmarshaledSignature(v: v, r: r, s: s)
    }
}

extension KeystoneSignFlow: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidScan(_ code: String) {
        guard
            let signature = URRegistry.shared.getSignature(from: code),
            let unmarshaledSignature = getUnmarshalSignature(signature: signature)
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
}
