//
//  OnboardingLedgerKeyViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingLedgerKeyViewController: AddKeyOnboardingViewController {
    private var deviceUUID: UUID?
    private var bluetoothController: BaseBluetoothController?
    private var selectedAddressInfo: LedgerAddressInfo?
    private var addressName: String?

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
            selectedAddressInfo = info
            showEnterName()
        }
        show(addressPickerVC, sender: nil)
    }

    func showEnterName() {
        guard let selectedAddressInfo = selectedAddressInfo else {
            return
        }

        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.actionTitle = "Import"
        enterNameVC.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        enterNameVC.screenTitle = "Enter Key Name"
        enterNameVC.trackingEvent = .ledgerEnterKeyName
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = selectedAddressInfo.defaultName
        enterNameVC.address = selectedAddressInfo.address
        enterNameVC.badgeName = KeyType.ledgerNanoX.imageName

        enterNameVC.completion = { [unowned self] name in
            guard importKey(name: name) else {
                return
            }
            self.addressName = name
            showCreatePasscode()
        }

        show(enterNameVC, sender: self)
    }

    func importKey(name: String) -> Bool {
        guard let selectedAddressInfo = selectedAddressInfo, let deviceId = deviceUUID else {
            return false
        }
        if (try? KeyInfo.firstKey(address: selectedAddressInfo.address)) != nil {
            App.shared.snackbar.show(error: GSError.KeyAlreadyImported())
            return false
        }
        let success = OwnerKeyController.importKey(
            ledgerDeviceUUID: deviceId,
            path: selectedAddressInfo.derivationPath,
            address: selectedAddressInfo.address,
            name: name
        )
        if success {
            AppSettings.hasShownImportKeyOnboarding = true
        }
        return success
    }

    func showCreatePasscode() {
        let createPasscodeVC = CreatePasscodeController { [unowned self] in
            dismiss(animated: true) { [unowned self] in
                showAddPushNotifications()
            }
        }
        guard let createPasscodeVC = createPasscodeVC else {
            showAddPushNotifications()
            return
        }
        present(createPasscodeVC, animated: true)
    }

    func showAddPushNotifications() {
        guard let selectedAddressInfo = selectedAddressInfo, let name = addressName else {
            return
        }

        let addPushesVC = LedgerKeyAddedViewController()
        addPushesVC.accountAddress = selectedAddressInfo.address
        addPushesVC.accountName = name
        addPushesVC.completion = { [unowned self] in
            showSuccessMessage()
        }
        show(addPushesVC, sender: self)
    }

    func showSuccessMessage() {
        App.shared.snackbar.show(message: "Owner key successfully added")
        self.completion()
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
