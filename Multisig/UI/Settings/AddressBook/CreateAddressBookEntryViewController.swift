//
//  CreateAddressBookEntryViewController.swift
//  Multisig
//
//  Created by Moaaz on 10/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeWeb3

class CreateAddressBookEntryViewController: UIViewController {
    var address: Address? { addressField?.address }
    var name: String? { textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) }

    var completion: ((Address, String) -> Void)?
    var chain: SCGModels.Chain!

    lazy var trackingParameters: [String: Any]  = { ["chain_id" : chain.id] }()
    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250
    
    @IBOutlet private weak var addressField: AddressField!
    @IBOutlet private weak var textField: GNOTextField!
    private var nextButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(chain != nil, "Developer error: expect to have a chain")
        
        navigationItem.title = "New Entry"

        addressField.setPlaceholderText("Enter entry address")

        addressField.onTap = { [weak self] in self?.didTapAddressField() }

        nextButton = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        nextButton.isEnabled = false

        navigationItem.rightBarButtonItem = nextButton

        textField.setPlaceholder("Enter entry name")
        textField.textField.delegate = self
        textField.textField.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.addressBookAddEntry)
    }

    @objc private func didTapNextButton(_ sender: Any) {
        guard let address = address else { return }
        completion?(address, name!)
    }

    private func didTapAddressField() {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .multiplatformActionSheet)

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
                                                  error: GSError.AddressNotValid()))
                }
            }
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.setup()
            self.present(vc, animated: true, completion: nil)
        }))

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

            // (2) and that there's no such entry already
            let exists = AddressBookEntry.exists(address.checksummed, chainId: chain.id)
            if exists { throw GSError.AddressBookEntryAlreadyExists() }
            validateInput()
        } catch {
            addressField.setError(
                GSError.error(description: "Can’t use this address",
                              error: error is EthereumAddress.Error ? GSError.AddressNotValid() : error))
        }
    }
    
    private func validateInput() {
        nextButton.isEnabled = address != nil && name != nil && !name!.isEmpty
    }
}

extension CreateAddressBookEntryViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.validateInput()
        })
        return true
    }
}

extension CreateAddressBookEntryViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }

    func scannerViewControllerDidScan(_ code: String) {
        didEnterText(code)
        dismiss(animated: true, completion: nil)
    }
}
