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
    @IBOutlet private weak var maxButton: UIButton!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var totalBalanceLabel: UILabel!
    @IBOutlet private weak var amountTextField: TokenAmountField!
    @IBOutlet private weak var reviewButton: UIButton!
    @IBOutlet private weak var scrollView: UIScrollView!

    var address: Address? { addressField?.address }
    var amount: String? { amountTextField.balance.isEmpty ? nil : amountTextField.balance }
    var tokenBalance: TokenBalance!
    var gatewayService = App.shared.clientGatewayService
    var safe: Safe!

    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250


    private var nextButton: UIBarButtonItem!

    private var keyboardBehavior: KeyboardAvoidingBehavior!

    override func viewDidLoad() {
        super.viewDidLoad()

        safe = try? Safe.getSelected()
        assert(safe != nil)

        navigationItem.title = "Send " + tokenBalance.symbol
        maxButton.setText("Send max", .primary)

        safeAddressInfoView.setAddress(safe.addressValue,
                                       label: safe.name,
                                       prefix: safe.chain!.shortName)

        addressField.setPlaceholderText("Recipient's address")
        addressField.onTap = { [weak self] in self?.didTapAddressField() }

        reviewButton.isEnabled = false

        balanceLabel.setStyle(.secondary)
        totalBalanceLabel.setStyle(.headline)

        
        totalBalanceLabel.text = tokenBalance.balanceWithSymbol

        reviewButton.setText("Review", .filled)
        amountTextField.setToken(symbol: tokenBalance.symbol, logoURL: tokenBalance.imageURL)
        amountTextField.delegate = self
        
        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardBehavior.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    @IBAction func maxButtonTouched(_ sender: Any) {
        amountTextField.balance = tokenBalance.balance
        verifyInput()
    }

    @IBAction private func didTapReviewButton(_ sender: Any) {
        let vc = ReviewSendFundsTransactionViewController()
        vc.address = address
        vc.safe = safe
        vc.amount = amount

        show(vc, sender: self)
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
            let address = try Address.addressWithPrefix(text: text)
            guard (address.prefix ?? safe.chain?.shortName) == safe.chain?.shortName else {
                addressField.setError(GSError.AddressMismatchNetwork())
                return
            }

            addressField.setAddress(address,
                                    label: NamingPolicy.name(for: address, chainId: safe.chain!.id!).name,
                                    prefix: safe.chain?.shortName)
        } catch {
            addressField.setError(
                GSError.error(description: "Can’t use this address",
                              error: error is EthereumAddress.Error ? GSError.SafeAddressNotValid() : error))
        }

        verifyInput()
    }

    func verifyInput() {
        // TODO: Verify that amount is less than balance
        reviewButton.isEnabled = address != nil && amount != nil
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

    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardBehavior.activeTextField = textField
    }
}
