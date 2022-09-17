//
//  ConnectKeystoneFlow.swift
//  Multisig
//
//  Created by Zhiying Fan on 15/8/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import URRegistry

final class ConnectKeystoneFlow: AddKeyFlow {
    var addKeyParameters: AddKeystoneKeyParameters?
    var sourceFingerprint: UInt32?
    
    var flowFactory: ConnectKeystoneFactory {
        factory as! ConnectKeystoneFactory
    }
    
    init(completion: @escaping (Bool) -> Void) {
        super.init(badge: KeyType.keystone.imageName, factory: ConnectKeystoneFactory(), completion: completion)
    }
    
    override func didIntro() {
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
            guard value.starts(with: "UR:CRYPTO-HDKEY") || value.starts(with: "UR:CRYPTO-ACCOUNT") else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
            return .success(value)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        navigationController.present(vc, animated: true)

        Tracker.trackEvent(.keystoneQRScanner)
    }
    
    func pickAccount(_ node: HDNode) {
        let pickerVC = flowFactory.derivedAccountPicker(node: node) { [unowned self] publicKey in
            didGetKey(addKeyParameters: publicKey)
        }
        show(pickerVC)
    }
    
    func didGetKey(addKeyParameters: AddKeystoneKeyParameters) {
        self.addKeyParameters = addKeyParameters
        enterName()
    }
    
    override func enterName() {
        guard let addKeyParameters = addKeyParameters else { return }
        let nameVC = factory.enterName(parameters: addKeyParameters) { [unowned self] name in
            keyName = name
            importKey()
        }
        show(nameVC)
    }
    
    override func importKey() {
        guard let addKeyParameters = addKeyParameters else { return }
        let existingKey = try? KeyInfo.firstKey(address: addKeyParameters.address)
        guard existingKey == nil else {
            App.shared.snackbar.show(error: GSError.KeyAlreadyImported())
            stop(success: false)
            return
        }

        let success = doImport()

        guard success, let key = try? KeyInfo.keys(addresses: [addKeyParameters.address]).first else {
            stop(success: false)
            return
        }

        keyInfo = AddressInfo(address: key.address, name: key.name)

        AppSettings.hasShownImportKeyOnboarding = true

        didImport()
    }
    
    override func doImport() -> Bool {
        if let addKeyParameters = addKeyParameters,
           let keyName = keyName,
           let sourceFingerprint = sourceFingerprint {
            return OwnerKeyController.importKey(
                keystone: addKeyParameters.address,
                path: addKeyParameters.derivationPath,
                name: keyName,
                sourceFingerprint: sourceFingerprint
            )
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
            if let hdKey = URRegistry.shared.getHDKey(from: code) {
                sourceFingerprint = hdKey.sourceFingerprint
                
                let hdNode = HDNode()
                hdNode.publicKey = Data(hex: hdKey.key)
                hdNode.chaincode = Data(hex: hdKey.chainCode)
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

class AddKeystoneKeyParameters: AddKeyParameters {
    var derivationPath: String

    init(address: Address, derivationPath: String) {
        self.derivationPath = derivationPath
        super.init(address: address, keyName: nil, badgeName: KeyType.keystone.imageName)
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

                .init(image: UIImage(named: "ico-onboarding-keystone-key"),
                      title: "How secure is that?",
                      body: "Your key will remain on your Keystone wallet. We do not store it in the app.")]
        introVC.viewTrackingEvent = .keystoneOwnerOnboarding
        introVC.navigationItem.title = "Connect Keystone"
        return introVC
    }
    
    func derivedAccountPicker(node: HDNode, completion: @escaping (_ addKeyParameters: AddKeystoneKeyParameters) -> Void) -> KeyPickerController {
        let viewModel = SelectOwnerAddressViewModel(rootNode: node)
        let pickDerivedKeyVC = KeyPickerController(viewModel: viewModel)
        pickDerivedKeyVC.completion = { [unowned pickDerivedKeyVC] in
            if let keyParameters = pickDerivedKeyVC.addKeystoneKeyParameters {
                completion(keyParameters)
            }
        }
        return pickDerivedKeyVC
    }
}
