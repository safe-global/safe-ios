//
//  TransactionViewController.swift
//  Multisig
//
//  Created by Moaaz on 10/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Web3

class TransactionViewController: UIViewController {
    @IBOutlet private weak var safeAddressInfoView: AddressInfoView!
    @IBOutlet private weak var addressField: AddressField!
    @IBOutlet private weak var amountTextField: GNOTextField!
    @IBOutlet private weak var maxButton: UIButton!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var totalBalanceLabel: UILabel!
    @IBOutlet private weak var reviewButton: UIButton!

    var address: Address? { addressField?.address }
    var amount: Double? { amountTextField.textField.text!.isEmpty ? nil : Double(amountTextField.textField.text!) }
    var tokenBalance: TokenBalance!
    var gatewayService = App.shared.clientGatewayService
    var safe: Safe!

    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250

    override func viewDidLoad() {
        super.viewDidLoad()

        safe = try? Safe.getSelected()
        assert(safe != nil)

        navigationItem.title = "Send " + tokenBalance.symbol
        maxButton.setText("Send max", .primary)

        safeAddressInfoView.setAddress(safe.addressValue, label: safe.name)

        addressField.setPlaceholderText("Recipient's address")
        addressField.onTap = { [weak self] in self?.didTapAddressField() }

        reviewButton.isEnabled = false

        amountTextField.setPlaceholder("Amount")
        amountTextField.textField.delegate = self
        amountTextField.textField.keyboardType = .decimalPad

        balanceLabel.setStyle(.secondary)
        totalBalanceLabel.setStyle(.headline)

        
        totalBalanceLabel.text = tokenBalance.balanceWithSymbol

        reviewButton.setText("Review", .filled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Tracker.trackEvent(.sendFundsTransaction)
    }

    @IBAction func maxButtonTouched(_ sender: Any) {
        amountTextField.textField.text = tokenBalance.balance
        verifyInput()
    }

    @IBAction private func didTapReviewButton(_ sender: Any) {

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
        reviewButton.isEnabled = false

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

            guard (address.prefix ?? safe.chain?.shortName) == safe.chain?.shortName else {
                addressField.setError(GSError.AddressMismatchNetwork())
                return
            }

            addressField.setAddress(address, prefix: safe.chain?.shortName)
        } catch {
            addressField.setError(
                GSError.error(description: "Can’t use this address",
                              error: error is EthereumAddress.Error ? GSError.SafeAddressNotValid() : error))
        }
    }

    func verifyInput() {
        reviewButton.isEnabled = address != nil && amount != nil && (amount! <= Double(tokenBalance.balance)!)
    }
}


extension TransactionViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }

    func scannerViewControllerDidScan(_ code: String) {
        didEnterText(code)
        dismiss(animated: true, completion: nil)
    }
}

extension TransactionViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.verifyInput()
        })
        return true
    }
}
