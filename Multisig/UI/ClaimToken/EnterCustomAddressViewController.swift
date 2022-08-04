//
//  EnterCustomAddressViewController.swift
//  Multisig
//
//  Created by Vitaly on 24.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Web3

class EnterCustomAddressViewController: UIViewController {

    @IBOutlet private weak var continueButton: UIButton!
    @IBOutlet private weak var addressField: AddressField!

    private var stepLabel: UILabel!
    private var stepNumber: Int = 2
    private var maxSteps: Int = 3

    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250

    private var chain: SCGModels.Chain!
    private var trackingParameters: [String: Any]?
    private var address: Address? { addressField?.address }

    var mainnet: Bool = true
    var onContinue: ((_ address: Address) -> ())?


    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.makeTransparentNavigationBar(self)
        navigationItem.hidesBackButton = false
        navigationItem.title = "Custom address"

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        addressField.setPlaceholderText("Enter delegate address")
        addressField.onTap = { [weak self] in self?.didTapAddressField() }

        continueButton.setText("Select & Continue", .filled)
        continueButton.isEnabled = false

        if mainnet {
            chain = SCGModels.Chain.mainnetChain()
        } else {
            chain = SCGModels.Chain.rinkebyChain()
        }

        trackingParameters = { ["chain_id" : chain.chainId.description] }()
    }

    private func didTapAddressField() {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let popoverPresentationController = alertVC.popoverPresentationController {
            popoverPresentationController.sourceView = addressField
        }
        alertVC.addAction(UIAlertAction(title: "Paste from Clipboard", style: .default, handler: { [weak self] _ in
            let text = Pasteboard.string
            self?.didEnterText(text)
        }))

        alertVC.addAction(UIAlertAction(title: "Scan QR Code", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let vc = QRCodeScannerViewController()
            vc.trackingParameters = self.trackingParameters
            vc.scannedValueValidator = { value in
                if let _ = try? Address.addressWithPrefix(text: value) {
                    return .success(value)
                } else {
                    return .failure(GSError.error(description: "Can’t use this QR code",
                                                  error: GSError.SafeAddressNotValid()))
                }
            }
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.setup()
            self.present(vc, animated: true, completion: nil)
        }))

        let blockchainDomainManager = BlockchainDomainManager(rpcURL: chain.authenticatedRpcUrl,
                                                              chainId: chain.id,
                                                              ensRegistryAddress: chain.ensRegistryAddress)
        if blockchainDomainManager.ens != nil {
            alertVC.addAction(UIAlertAction(title: "Enter ENS Name", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                let ensNameVC = EnterENSNameViewController(manager: blockchainDomainManager, chain: self.chain)
                ensNameVC.trackingParameters = self.trackingParameters
                ensNameVC.onConfirm = { [weak self] in
                    guard let `self` = self else { return }
                    self.navigationController?.popViewController(animated: true)
                    self.didEnterText(ensNameVC.address?.checksummed)
                }
                let ensNameWrapperVC = RibbonViewController(rootViewController: ensNameVC)
                ensNameWrapperVC.chain = self.chain
                self.show(ensNameWrapperVC, sender: nil)
            }))
        }

        if blockchainDomainManager.unstoppableDomainResolution != nil {
            alertVC.addAction(UIAlertAction(title: "Enter Unstoppable Name", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                let udNameVC = EnterUnstoppableNameViewController(manager: blockchainDomainManager, chain: self.chain)
                udNameVC.trackingParameters = self.trackingParameters
                udNameVC.onConfirm = { [weak self] in
                    guard let `self` = self else { return }
                    self.navigationController?.popViewController(animated: true)
                    self.didEnterText(udNameVC.address?.checksummed)
                }
                let udNameWrapperVC = RibbonViewController(rootViewController: udNameVC)
                udNameWrapperVC.chain = self.chain
                self.show(udNameWrapperVC, sender: nil)
            }))
        }

        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertVC, animated: true, completion: nil)
    }

    private func didEnterText(_ text: String?) {
        addressField.clear()
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }

        guard !text.isEmpty else {
            addressField.setError("Address should not be empty")
            return
        }
        addressField.setInputText(text)
        do {
            // (1) validate that the text is address
            let address = try Address.addressWithPrefix(text: text)

            guard (address.prefix ?? chain.shortName) == chain.shortName else {
                addressField.setError(GSError.AddressMismatchNetwork())
                return
            }

            addressField.setAddress(address, prefix: chain.shortName)

            validateInput()

        } catch {
            addressField.setError(
                GSError.error(description: "Can’t use this address",
                              error: error is EthereumAddress.Error ? GSError.AddressNotValid() : error))
        }
    }

    private func validateInput() {
       continueButton.isEnabled = address != nil
    }

    @IBAction func didTapContinueButton(_ sender: Any) {
        onContinue?(address!)
    }
}

extension EnterCustomAddressViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.validateInput()
        })
        return true
    }
}

extension EnterCustomAddressViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }

    func scannerViewControllerDidScan(_ code: String) {
        didEnterText(code)
        dismiss(animated: true, completion: nil)
    }
}
