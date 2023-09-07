//
//  LedgerKeyFlow.swift
//  Multisig
//
//  Created by Mouaz on 11/4/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerKeyFlow: AddKeyFlow {
    private var bluetoothController: BaseBluetoothController?

    var flowFactory: LedgerKeyFlowFactory {
        factory as! LedgerKeyFlowFactory
    }

    var parameters: AddLedgerKeyParameters? {
        keyParameters as? AddLedgerKeyParameters
    }

    init(completion: @escaping (Bool) -> Void) {
        super.init(factory: LedgerKeyFlowFactory(), completion: completion)
    }

    override func didIntro() {
        selectDevice()
    }

    func selectDevice() {
        let vc = flowFactory.selectDevice { [unowned self] deviceId, controller  in
            bluetoothController = controller
            addressPicker(deviceUUID: deviceId)
        }

        show(vc)
    }

    func addressPicker(deviceUUID: UUID) {
        assert(bluetoothController != nil)
        let vc = flowFactory.addressPicker(deviceUUID: deviceUUID,
                                           bluetoothController: bluetoothController!) { [unowned self] key, name, path in
            keyParameters = AddLedgerKeyParameters(address: key.address, keyName: name, index: key.index, derivationPath: path, deviceUUID: deviceUUID)
            didGetKey()
        }

        show(vc)
    }

    override func doImport() -> Bool {
        guard let address = parameters?.address,
              let deviceUUID = parameters?.deviceUUID,
              let name = parameters?.name,
              let path = parameters?.derivationPath else {
            assertionFailure("Missing key arguments")
            return false
        }
        
        return OwnerKeyController.importKey(
            ledgerDeviceUUID: deviceUUID,
                path: path,
                address: address,
                name: name
        )
    }
}

class LedgerKeyFlowFactory: AddKeyFlowFactory {
    override func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = super.intro(completion: completion)
        introVC.cards = [
            .init(image: UIImage(named: "ico-onboarding-ledger"),
                  title: "How does it work?",
                  body: "You can connect your Ledger device and select a key. If it is an owner of your Safe Account you can sign transactions."),

                .init(image: UIImage(named: "ico-onboarding-bluetooth"),
                      title: "Pair your Ledger device",
                      body: "Please make sure your Ledger Nano X is unlocked, Bluetooth is enabled and Ethereum app is installed and opened."),

                .init(image: UIImage(named: "ico-onboarding-key"),
                      title: "How secure is that?",
                      body: "Your key will remain on your Ledger wallet. We do not store it in the app.")
        ]
        introVC.viewTrackingEvent = .ledgerOwnerOnboarding
        introVC.navigationItem.title = "Connect Ledger Nano X"
        introVC.navigationItem.largeTitleDisplayMode = .never
        return introVC
    }

    func selectDevice(completion: @escaping (UUID, BaseBluetoothController) -> Void) -> SelectLedgerDeviceViewController {
        let vc = SelectLedgerDeviceViewController(trackingParameters: ["action" : "import"],
                                                  title: "Connect Ledger Nano X",
                                                  showsCloseButton: false)
        vc.completion = completion
        
        return vc
    }

    func addressPicker(deviceUUID: UUID,
                       bluetoothController: BaseBluetoothController,
                       completion: @escaping ((KeyAddressInfo, String?, String) -> Void)) -> LedgerKeyPickerViewController {
        let addressPickerVC = LedgerKeyPickerViewController(
            deviceId: deviceUUID,
            bluetoothController: bluetoothController)
        addressPickerVC.completion = completion

        return addressPickerVC
    }
}

class AddLedgerKeyParameters: AddKeyParameters {
    var index: Int
    var derivationPath: String
    var deviceUUID: UUID

    init(address: Address, keyName: String?, index: Int, derivationPath: String, deviceUUID: UUID) {
        self.index = index
        self.derivationPath = derivationPath
        self.deviceUUID = deviceUUID
        super.init(address: address, name: keyName, type: KeyType.ledgerNanoX)
    }
}
