//
//  OnboardingLedgerKeyViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingLedgerKeyViewController: AddKeyOnboardingViewController {
    convenience init(completion: @escaping () -> Void) {
        #warning("TODO: change image for 'Pair your Ledger device' onboarding card")
        self.init(
            cards: [
                .init(image: UIImage(named: "ico-onbaording-import-key-1"),
                      title: "How does it work?",
                      body: "You can connect your Ledger device and select a key. If it is an owner of your Safe you can sign transactions."),

                .init(image: UIImage(named: "ico-onbaording-import-key-2"),
                      title: "Pair your Ledger device",
                      body: "Please make sure your Ledger Nano X is unlocked, Bluetooth is enabled and Ethereum app is installed and opened."),

                .init(image: UIImage(named: "ico-onbaording-import-key-2"),
                      title: "How secure is that?",
                      body: "Your key will remain on your Ledger wallet. We do not store it in the app.")
            ],
            viewTrackingEvent: .ledgerOwnerOnboarding,
            completion: completion)
        navigationItem.title = "Connect Ledger Wallet"
    }

    override func didTapNextButton(_ sender: Any) {
        let vc = SelectLedgerDeviceViewController(trackingParameters: ["action" : "import"])
        vc.delegate = self
        show(vc, sender: self)
    }
}

extension OnboardingLedgerKeyViewController: SelectLedgerDeviceDelegate {
    func selectLedgerDeviceViewController(_ controller: SelectLedgerDeviceViewController,
                                          didSelectDevice deviceId: UUID,
                                          bluetoothController: BluetoothController) {

        let keyPickerController = LedgerKeyPickerViewController(deviceId: deviceId,
                                                                bluetoothController: bluetoothController,
                                                                completion: completion)
        show(keyPickerController, sender: nil)
    }
}
