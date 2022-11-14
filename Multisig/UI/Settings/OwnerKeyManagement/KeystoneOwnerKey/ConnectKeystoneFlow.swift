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
    private static let urPrefixOfHDKey = "UR:CRYPTO-HDKEY"
    private static let urPrefixOfAccount = "UR:CRYPTO-ACCOUNT"
    private var scannerVC: QRCodeScannerViewController!
    private var addKeyParameters: AddKeystoneKeyParameters?
    private var sourceFingerprint: UInt32?
    
    private var flowFactory: ConnectKeystoneFactory {
        factory as! ConnectKeystoneFactory
    }
    
    init(completion: @escaping (Bool) -> Void) {
        super.init(keyType: .keystone, factory: ConnectKeystoneFactory(), completion: completion)
    }
    
    override func didIntro() {
        URRegistry.shared.resetDecoder()
        scan()
    }
    
    private func scan() {
        scannerVC = QRCodeScannerViewController()
        let string = "Scan your Keystone wallet QR code to connect." as NSString
        let textStyle = GNOTextStyle.bodyPrimary.color(.white)
        let highlightStyle = textStyle.weight(.bold)
        let label = NSMutableAttributedString(string: string as String, attributes: textStyle.attributes)
        label.setAttributes(highlightStyle.attributes, range: string.range(of: "Keystone"))
        scannerVC.attributedLabel = label

        scannerVC.scannedValueValidator = { value in
            guard value.starts(with: Self.urPrefixOfHDKey) || value.starts(with: Self.urPrefixOfAccount) else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
            return .success(value)
        }
        scannerVC.modalPresentationStyle = .overFullScreen
        scannerVC.delegate = self
        scannerVC.setup()
        navigationController.present(scannerVC, animated: true)

        Tracker.trackEvent(.keystoneQRScanner)
    }
    
    func pickAccount(_ viewModel: KeystoneSelectAddressViewModel) {
        let pickerVC = flowFactory.derivedAccountPicker(viewModel: viewModel) { [unowned self] addKeyParameters in
            didGetKey(addKeyParameters: addKeyParameters)
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
        if let keyAddress = keyAddress,
           let keyInfo = try? KeyInfo.firstKey(address: keyAddress) {
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
        if code.starts(with: Self.urPrefixOfHDKey) {
            navigationController.dismiss(animated: true) { [unowned self] in
                if let hdKey = URRegistry.shared.getSourceHDKey(from: code) {
                    sourceFingerprint = hdKey.sourceFingerprint
                    
                    let viewModel = KeystoneSelectAddressViewModel(hdKey: hdKey)
                    pickAccount(viewModel)
                } else {
                    App.shared.snackbar.show(error: GSError.InvalidWalletConnectQRCode())
                }
            }
        } else if code.starts(with: Self.urPrefixOfAccount) {
            guard let hdKeys = URRegistry.shared.getHDKeys(from: code) else {
                DispatchQueue.global().async { [unowned self] in
                    scannerVC.captureSession.startRunning()
                }
                return
            }
            
            navigationController.dismiss(animated: true) { [unowned self] in
                sourceFingerprint = hdKeys.first?.sourceFingerprint
                let viewModel = KeystoneSelectAddressViewModel(hdKeys: hdKeys)
                pickAccount(viewModel)
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
    
    func derivedAccountPicker(viewModel: KeystoneSelectAddressViewModel, completion: @escaping (_ addKeyParameters: AddKeystoneKeyParameters) -> Void) -> KeyPickerController {
        let pickDerivedKeyVC = KeyPickerController(viewModel: viewModel)
        pickDerivedKeyVC.completion = { [unowned pickDerivedKeyVC] in
            if let keyParameters = pickDerivedKeyVC.addKeystoneKeyParameters {
                completion(keyParameters)
            }
        }
        return pickDerivedKeyVC
    }
}
