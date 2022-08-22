//
//  ConnectKeystoneFlow.swift
//  Multisig
//
//  Created by Zhiying Fan on 15/8/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import URKit

final class ConnectKeystoneFlow: AddKeyFlow {
    var flowFactory: ConnectKeystoneFactory {
        factory as! ConnectKeystoneFactory
    }
    
    init(completion: @escaping (Bool) -> Void) {
        super.init(badge: KeyType.keystone.imageName, factory: ConnectKeystoneFactory(), completion: completion)
    }
    
    override func didIntro() {
        super.didIntro()
        scan()
    }
    
    private func scan() {
        let vc = QRCodeScannerViewController()

        let string = "Scan your Keystone wallet QR code to connect." as NSString
        let textStyle = GNOTextStyle.primary.color(.white)
        let highlightStyle = textStyle.weight(.bold)
        let label = NSMutableAttributedString(string: string as String, attributes: textStyle.attributes)
        label.setAttributes(highlightStyle.attributes, range: string.range(of: "Keystone"))
        vc.attributedLabel = label

        vc.scannedValueValidator = { value in
            if let decodedUR = try? URDecoder.decode(value),
               KeystoneURValidator.validate(urType: decodedUR.type) {
                return .success(value)
            } else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        navigationController.present(vc, animated: true)

        Tracker.trackEvent(.keystoneQRScanner)
    }
    
    func pickAccount(_ node: HDNode) {
        let pickerVC = flowFactory.derivedAccountPicker(node: node) { [unowned self] privateKey in
            didGetKey(privateKey: privateKey)
        }
        show(pickerVC)
    }
    
    override func doImport() -> Bool {
        if let privateKey = privateKey,
           let keyName = keyName {
            return OwnerKeyController.importKey(keystone: privateKey, name: keyName)
        } else {
            return false
        }
    }
    
    override func didImport() {
        if let addressInfo = keyInfo,
           let keyInfo = try? KeyInfo.firstKey(address: addressInfo.address) {
            let keyVC = flowFactory.details(keyInfo: keyInfo) { [unowned self] in
                stop(success: true)
            }
            show(keyVC)
        } else {
            stop(success: true)
        }
    }
}

extension ConnectKeystoneFlow: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidScan(_ code: String) {
        navigationController.dismiss(animated: true) { [unowned self] in
            if let decodedUR = try? URDecoder.decode(code),
               let hdNode = HDNode(seed: decodedUR.cbor) {
                pickAccount(hdNode)
            } else {
                App.shared.snackbar.show(error: GSError.InvalidWalletConnectQRCode())
            }
        }
    }
    
    func scannerViewControllerDidCancel() {
        navigationController.dismiss(animated: true)
    }
}

final class ConnectKeystoneFactory: AddKeyFlowFactory {
    override func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = super.intro(completion: completion)
        introVC.cards = [
            .init(image: UIImage(named: "ico-onboarding-keystone-device"),
                  title: "How does it work?",
                  body: "Connect your Keystone device and select a key. If it is an owner of your Safe you can sign transactions."),

                .init(image: UIImage(named: "ico-onboarding-keystone-qrcode"),
                      title: "Secured QR codes",
                      body: "Sign anywhere without USB cables or unstable bluetooth via secured and verifiable QR codes."),

                .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                      title: "How secure is that?",
                      body: "Your key will remain on your Keystone wallet. We do not store it in the app.")]
        introVC.viewTrackingEvent = .keystoneOwnerOnboarding
        introVC.navigationItem.title = "Connect Keystone"
        return introVC
    }
    
    func derivedAccountPicker(node: HDNode, completion: @escaping (_ privateKey: PrivateKey) -> Void) -> KeyPickerController {
        let pickDerivedKeyVC = KeyPickerController(node: node)
        pickDerivedKeyVC.completion = { [unowned pickDerivedKeyVC] in
            let key = pickDerivedKeyVC.privateKey!
            completion(key)
        }
        return pickDerivedKeyVC
    }
    
    func details(keyInfo: KeyInfo, completion: @escaping () -> Void) -> OwnerKeyDetailsViewController {
        OwnerKeyDetailsViewController(keyInfo: keyInfo, completion: completion)
    }
}
