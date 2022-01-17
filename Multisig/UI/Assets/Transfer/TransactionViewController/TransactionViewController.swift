//
//  TransactionViewController.swift
//  Multisig
//
//  Created by Moaaz on 10/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Web3
import SwiftCryptoTokenFormatter

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
    var amount: BigDecimal? {
        amountTextField.balance.isEmpty ? nil : BigDecimal.create(string: amountTextField.balance, precision: tokenBalance.decimals)
    }
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
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        
        maxButton.setText("Send max", .primary)
        maxButton.contentHorizontalAlignment = .right

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
        amountTextField.setToken(logoURL: tokenBalance.imageURL)
        amountTextField.delegate = self
        
        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.assetsTransferInit)
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
        guard let amount = amount, let address = address else { return }

        let vc = ReviewSendFundsTransactionViewController(safe: safe,
                                                          address: address,
                                                          tokenBalance: tokenBalance,
                                                          amount: amount)
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
        amountTextField.showError(message: nil)
        reviewButton.isEnabled = false

        guard let amount = amount else { return }

        var message: String? = nil

        if amount.value <= 0 {
            message = "Amount should be greater than 0"
        }

        else if amountTextField.balance.numberOfDecimals > tokenBalance.decimals {
            message = "Should be 1 to \(tokenBalance.decimals) decimals"
        }

        else if amount.value > tokenBalance.balanceValue.value {
            message = "Insufficient funds"
        }

        reviewButton.isEnabled = message == nil && address != nil
        amountTextField.showError(message: message)
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


extension BigDecimal {
    static func create(string: String, precision: Int) -> BigDecimal? {
        TokenFormatter().number(from: string, precision: precision)
    }
}

//extension BigDecimal {
//    static func create(string: String) -> BigDecimal? {
//        var precision: Int = 0
//        let tokenFormatter = TokenFormatter()
//        let decimalSeparator = Locale.autoupdatingCurrent.decimalSeparator ?? "."
//
//        let parts = string.removingTrailingZeroes.components(separatedBy: CharacterSet(charactersIn: decimalSeparator))
//        if parts.count == 1 { precision = 0 }
//        if parts.count > 2 { precision = parts.last?.count ?? 0 }
//
//        return tokenFormatter.number(from: string, precision: precision)
//    }
//}
//
extension String {
    var removingTrailingZeroes: String {
        var result = self
        while result.last == "0" {
            result.removeLast()
        }
        return result
    }

    var numberOfDecimals: Int {
        let decimalSeparator = Locale.autoupdatingCurrent.decimalSeparator ?? "."
        let parts = removingTrailingZeroes.components(separatedBy: decimalSeparator)
        if parts.count >= 2 { return parts.last?.count ?? 0 }

        return 0
    }
}
