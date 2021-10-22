//
//  CreateAddressBookEntityViewController.swift
//  Multisig
//
//  Created by Moaaz on 10/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Web3

class CreateAddressBookEntityViewController: UIViewController {
    var address: Address? { addressField?.address }
    var name: String?

    var completion: ((Address, String) -> Void)?
    var chainId: String?

    lazy var trackingParameters: [String: Any]  = { ["chain_id" : chainId] }()
    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250
    
    @IBOutlet private weak var addressField: AddressField!
    @IBOutlet private weak var textField: GNOTextField!
    private var nextButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(chainId != nil, "Developer error: expect to have a chainId")
        
        navigationItem.title = "New Entity"

        addressField.setPlaceholderText("Enter entity address")

        addressField.onTap = { [weak self] in self?.didTapAddressField() }

        nextButton = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        nextButton.isEnabled = false

        navigationItem.rightBarButtonItem = nextButton

        textField.setPlaceholder("Enter entity name")
        textField.textField.delegate = self
        textField.textField.becomeFirstResponder()
        if let name = name {
            textField.textField.text = name
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.addressbookAddEntity)
    }

    @objc private func didTapNextButton(_ sender: Any) {
        guard let address = address else { return }
        completion?(address, name!)
    }

    private func didTapAddressField() {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertVC.addAction(UIAlertAction(title: "Paste from Clipboard", style: .default, handler: { [weak self] _ in
            let text = Pasteboard.string
            self?.didEnterText(text)
        }))

        alertVC.addAction(UIAlertAction(title: "Scan QR Code", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let vc = QRCodeScannerViewController()
            vc.trackingParameters = self.trackingParameters
            vc.scannedValueValidator = { value in
                if Address(value) != nil {
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

        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertVC, animated: true, completion: nil)
    }

    private func didEnterText(_ text: String?) {
        addressField.clear()
        nextButton.isEnabled = false

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
            let address = try Address(text, isERC681: true)
            addressField.setAddress(address)

            // (2) and that there's no such safe already
            let exists = AddressBookEntity.exists(address.checksummed, chainId: chainId!)
            if exists { throw GSError.AddressBookEntityAlreadyExists() }
        } catch {
            addressField.setError(
                GSError.error(description: "Can’t use this address",
                              error: error is EthereumAddress.Error ? GSError.AddressBookEntityAddressNotValid() : error))
        }
    }
    
    private func validateName() {
        nextButton.isEnabled = false
        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            self.name = nil
            return
        }
        self.name = text
        nextButton.isEnabled = true
    }
}

extension CreateAddressBookEntityViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.validateName()
        })
        return true
    }
}


extension CreateAddressBookEntityViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }

    func scannerViewControllerDidScan(_ code: String) {
        didEnterText(code)
        dismiss(animated: true, completion: nil)
    }
}
