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
import SafeWeb3
import Solidity

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
        let DEBUG_SIGNATURE = "0x99a7a03e9597e85a0cc4188d270b72b1df2de943de804f144976f4c1e23116ff274d2dec4ee7201b88bdadf08259a5dc8e7e2bbf372347de3470beeab904e5d01b"
        guard
            let signature = URRegistry.shared.getSignature(from: code)?.signature,
            let signatureComps = SECP256K1.UnmarshaledSignature(
                keystoneSignature: DEBUG_SIGNATURE,
                isLegacyTx: signInfo.signType == .transaction,
                chainId: signInfo.chain?.id ?? "0"),
            let requestId = URRegistry.shared.getSignature(from: code)?.requestId,
            signRequest.requestId.starts(with: requestId)
        else {
            stop(success: false)
            return
        }
        
        signCompletion?(SECP256K1.UnmarshaledSignature(v: signatureComps.v, r: signatureComps.r, s: signatureComps.s))
        stop(success: true)
    }
    
    func scannerViewControllerDidCancel() {
        stop(success: false)
    }
}

extension SECP256K1.UnmarshaledSignature {
    var safeSignature: String {
        let signature = r + s + Data([v + 4])
        return signature.toHexStringWithPrefix()
    }
    
    init?(keystoneSignature signature: String, isLegacyTx: Bool, chainId: String) {
        let data: Data = Data(hex: signature)
        guard data.count >= 65 else { return nil }
        
        let r = data[0..<32]
        let s = data[32..<64]
        let v: UInt8
        
        let chainIdInt = UInt64(chainId) ?? 0
        let vBytes: Bytes
        
        // if v was overflown (e.g. chain_id > 109 according to EIP-155)
        let chainIdTerm: UInt8 = UInt8((Sol.UInt128(chainIdInt) * 2 + 35) % 256)
        if data.count > 65 {
            // max 8 bytes to fit into UInt64
            let vBytes = [UInt8](data.suffix(from: 64).prefix(8))
            let vInt =  UInt64(vBytes)
            // recover V by deducting (chainId * 2 + 35) according to EIP-155
            v = try! UInt8(vInt % 256) - chainIdTerm
        } else {
            vBytes = [UInt8]([data[64]])
            let vInt = UInt8(vBytes)
            if isLegacyTx {
                // Legacy ethereum (pre-eip-155) adds 27 to v
                v = vInt - 27
            } else {
                // v still can be `{0, 1} + chainId * 2 + 35` for non-legacy transactions (chainId >=0)
                if vInt >= 35 {
                    if vInt > chainIdTerm {
                        v = vInt - chainIdTerm
                    } else {
                        v = 0
                    }
                } else {
                    v = vInt
                }
            }
        }
        
        // see https://github.com/Boilertalk/secp256k1/blob/d5407179912e8c1f825a212a474aaa86b10f1352/src/ecdsa_impl.h
        assert(v == 0 || v == 1 || v == 2 || v == 3 ||  v == 27 || v == 28 || v == 29 || v == 30)
        
        self.v = v
        self.r = r
        self.s = s
    }
}

