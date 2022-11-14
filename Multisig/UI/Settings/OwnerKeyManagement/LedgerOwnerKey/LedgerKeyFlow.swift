//
//  LedgerKeyFlow.swift
//  Multisig
//
//  Created by Mouaz on 11/4/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerKeyFlow: AddKeyFlow {
    private var deviceUUID: UUID?
    private var bluetoothController: BaseBluetoothController?
    var keyParameters: AddKeyParameters?

    var flowFactory: LedgerKeyFlowFactory {
        factory as! LedgerKeyFlowFactory
    }

    init(completion: @escaping (Bool) -> Void) {
        super.init(keyType: .ledgerNanoX, factory: LedgerKeyFlowFactory(), completion: completion)
    }

    override func didIntro() {
        selectWallet()
    }

    func selectWallet() {
        let vc = flowFactory.selectDevice { [unowned self] deviceId, controller  in
            deviceUUID = deviceId
            bluetoothController = controller
            addressPicker()
        } onClose: {

        }

        show(vc)
    }

    func addressPicker() {
        assert(deviceUUID != nil)
        assert(bluetoothController != nil)
        let vc = factory.addressPicker(deviceUUID: deviceUUID!, bluetoothController: bluetoothController!) { [unowned self] info in
            keyParameters = info
            didGet(key: info.address)
        }
    }

    override func doImport() -> Bool {
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
}

class LedgerKeyFlowFactory: AddKeyFlowFactory {
    override func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = super.intro(completion: completion)
        introVC.cards = [
            .init(image: UIImage(named: "ico-onboarding-ledger"),
                  title: "How does it work?",
                  body: "You can connect your Ledger device and select a key. If it is an owner of your Safe you can sign transactions."),

                .init(image: UIImage(named: "ico-onboarding-bluetooth"),
                      title: "Pair your Ledger device",
                      body: "Please make sure your Ledger Nano X is unlocked, Bluetooth is enabled and Ethereum app is installed and opened."),

                .init(image: UIImage(named: "ico-onboarding-key"),
                      title: "How secure is that?",
                      body: "Your key will remain on your Ledger wallet. We do not store it in the app.")
        ]
        introVC.viewTrackingEvent = .ledgerOwnerOnboarding
        introVC.navigationItem.title = "Connect Ledger Nano X"
        return introVC
    }

    func selectDevice(completion: @escaping (UUID, BaseBluetoothController) -> Void, onClose: (() -> Void)?) -> SelectLedgerDeviceViewController {
        let vc = SelectLedgerDeviceViewController(trackingParameters: ["action" : "import"],
                                                  title: "Connect Ledger Nano X",
                                                  showsCloseButton: false)
        vc.onClose = onClose
        vc.completion = completion
        
        return vc
    }

    func addressPicker(deviceUUID: UUID,
                       bluetoothController: BaseBluetoothController,
                       completion: @escaping ((AddLedgerKeyParameters) -> Void)) -> LedgerKeyPickerViewController {
        let addressPickerVC = LedgerKeyPickerViewController(
            deviceId: deviceUUID,
            bluetoothController: bluetoothController)
        addressPickerVC.completion = completion

        return addressPickerVC
    }
}
