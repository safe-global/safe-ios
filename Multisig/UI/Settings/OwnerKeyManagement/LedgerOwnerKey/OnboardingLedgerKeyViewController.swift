//
//  OnboardingLedgerKeyViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddLedgerKeyParameters: AddKeyParameters {
    var index: Int
    var derivationPath: String

    init(address: Address, keyName: String?, index: Int, derivationPath: String) {
        self.index = index
        self.derivationPath = derivationPath
        super.init(address: address, keyName: keyName, badgeName: KeyType.ledgerNanoX.imageName, keyNameTrackingEvent: .ledgerEnterKeyName)
    }
}

class OnboardingLedgerKeyViewController: AddKeyOnboardingViewController {
    private var deviceUUID: UUID?
    private var bluetoothController: BaseBluetoothController?

    convenience init(completion: @escaping () -> Void) {
        self.init(
            cards: [
                .init(image: UIImage(named: "ico-onboarding-ledger"),
                      title: "How does it work?",
                      body: "You can connect your Ledger device and select a key. If it is an owner of your Safe you can sign transactions."),

                .init(image: UIImage(named: "ico-onboarding-bluetooth"),
                      title: "Pair your Ledger device",
                      body: "Please make sure your Ledger Nano X is unlocked, Bluetooth is enabled and Ethereum app is installed and opened."),

                .init(image: UIImage(named: "ico-onboarding-key"),
                      title: "How secure is that?",
                      body: "Your key will remain on your Ledger wallet. We do not store it in the app.")
            ],
            viewTrackingEvent: .ledgerOwnerOnboarding,
            completion: completion)
        navigationItem.title = "Connect Ledger Nano X"
    }

    override func didTapNextButton(_ sender: Any) {
        showConnectToLedgerDevice()
    }

    func showConnectToLedgerDevice() {
        let vc = SelectLedgerDeviceViewController(trackingParameters: ["action" : "import"],
                                                  title: "Connect Ledger Nano X",
                                                  showsCloseButton: false)
        vc.delegate = self
        show(vc, sender: self)
    }

    func showAddressPicker() {
        guard let deviceId = deviceUUID, let bluetoothController = bluetoothController else {
            return
        }

        let addressPickerVC = LedgerKeyPickerViewController(
            deviceId: deviceId,
            bluetoothController: bluetoothController)
        addressPickerVC.completion = { [unowned self] info in
            keyParameters = info
            enterName()
        }
        show(addressPickerVC, sender: nil)
    }

    override func doImportKey() -> Bool {
        guard let keyParameters = keyParameters as? AddLedgerKeyParameters, let deviceId = deviceUUID else {
            return false
        }
        return OwnerKeyController.importKey(
                ledgerDeviceUUID: deviceId,
                path: keyParameters.derivationPath,
                address: keyParameters.address,
                name: keyParameters.keyName!
        )
    }

    override func didCreatePasscode() {
        showAddPushNotifications()
    }

    func showAddPushNotifications() {
        guard let keyParameters = keyParameters as? AddLedgerKeyParameters else {
            return
        }

        let addPushesVC = LedgerKeyAddedViewController()
        addPushesVC.accountAddress = keyParameters.address
        addPushesVC.accountName = keyParameters.keyName
        addPushesVC.completion = { [unowned self] in
            showSuccessMessage()
        }
        show(addPushesVC, sender: self)
    }
}

extension OnboardingLedgerKeyViewController: SelectLedgerDeviceDelegate {
    func selectLedgerDeviceViewController(_ controller: SelectLedgerDeviceViewController,
                                          didSelectDevice deviceId: UUID,
                                          bluetoothController: BaseBluetoothController) {
        self.deviceUUID = deviceId
        self.bluetoothController = bluetoothController
        showAddressPicker()
    }
}
