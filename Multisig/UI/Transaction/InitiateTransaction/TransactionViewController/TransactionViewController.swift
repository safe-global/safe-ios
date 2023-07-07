//
//  TransactionViewController.swift
//  Multisig
//
//  Created by Moaaz on 10/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeWeb3
import SwiftCryptoTokenFormatter
import Ethereum
import Solidity

class TransactionViewController: UIViewController {
    @IBOutlet private weak var safeAddressInfoView: AddressInfoView!
    @IBOutlet private weak var addressField: AddressField!
    @IBOutlet private weak var maxButton: UIButton!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var totalBalanceLabel: UILabel!
    @IBOutlet private weak var amountTextField: TokenAmountField!
    @IBOutlet private weak var reviewButton: UIButton!
    @IBOutlet private weak var scrollView: UIScrollView!

    private var tooltipSource: TooltipSource?

    var address: Address? { addressField?.address }
    var amount: BigDecimal? {
        amountTextField.balance.isEmpty ? nil : BigDecimal.create(string: amountTextField.balance, precision: tokenBalance.decimals)
    }
    var tokenBalance: TokenBalance!
    var gatewayService = App.shared.clientGatewayService
    var safe: Safe!

    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250


    private var reviewBarButton: UIBarButtonItem!

    private var keyboardBehavior: KeyboardAvoidingBehavior!

    override func viewDidLoad() {
        super.viewDidLoad()

        safe = try? Safe.getSelected()
        assert(safe != nil)

        navigationItem.title = "Send " + tokenBalance.symbol
        navigationItem.backButtonTitle = "Back"
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        reviewBarButton = UIBarButtonItem(title: "Review", style: .done, target: self, action: #selector(review))
        navigationItem.rightBarButtonItem = reviewBarButton
        
        maxButton.setText("Send max", .primary)
        maxButton.contentHorizontalAlignment = .right

        safeAddressInfoView.setAddress(safe.addressValue,
                                       label: safe.name,
                                       prefix: safe.chain!.shortName)

        addressField.setPlaceholderText("Recipient's address")
        addressField.onTap = { [weak self] in self?.didTapAddressField() }

        enableReviewButtons(false)

        balanceLabel.setStyle(.bodyMedium)
        totalBalanceLabel.setStyle(.bodyPrimary)

        
        totalBalanceLabel.text = tokenBalance.balanceWithSymbol

        tooltipSource = TooltipSource(target: totalBalanceLabel, arrowTarget: totalBalanceLabel)
        tooltipSource?.message = tokenBalance.fullBalanceWithSymbol
        tooltipSource?.aboveTarget = false

        reviewButton.setText("Review", .filled)
        amountTextField.setToken(logoURL: tokenBalance.imageURL)
        amountTextField.delegate = self
        
        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)

        if #unavailable(iOS 15) {
            // explicitly set background color to prevent transparent background in dark mode (iOS 14)
            navigationController?.navigationBar.backgroundColor = .backgroundSecondary
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.assetsTransferInit)
        keyboardBehavior.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
        TooltipSource.hideAll()
    }

    @IBAction func maxButtonTouched(_ sender: Any) {
        // string will format full amount without any rounding
        let value = Sol.UInt256(big: tokenBalance.balanceValue.value.magnitude)
        let tokenAmount = Eth.TokenAmount(
            value: value,
            decimals: tokenBalance.decimals)
        amountTextField.balance = tokenAmount.description
        verifyInput()
        TooltipSource.hideAll()
    }

    @IBAction private func didTapReviewButton(_ sender: Any) {
        review()
    }

    @objc private func review() {
        guard let amount = amount, let address = address else { return }
    
        let vc = ReviewSendFundsTransactionViewController(safe: safe,
                                                          recipient: address,
                                                          tokenBalance: tokenBalance,
                                                          amount: amount)
        show(vc, sender: self)
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

        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertVC, animated: true, completion: nil)
    }

    private func didEnterText(_ text: String?) {
        addressField.clear()
        enableReviewButtons(false)

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

    private func enableReviewButtons(_ enabled: Bool) {
        reviewButton.isEnabled = enabled
        reviewBarButton.isEnabled = enabled
    }

    func verifyInput() {
        amountTextField.showError(message: nil)
        enableReviewButtons(false)

        guard let amount = amount else { return }

        var message: String? = nil

        if amountTextField.balance.numberOfDecimals > tokenBalance.decimals {
            message = "Should be 1 to \(tokenBalance.decimals) decimals"
        } else if amount.value <= 0 {
            message = "Amount should be greater than 0"
        } else if amount.value > tokenBalance.balanceValue.value {
            message = "Insufficient funds"
        }

        enableReviewButtons(message == nil && address != nil)
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
        amountTextField.updateBorder()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        amountTextField.updateBorder()
    }
}


extension BigDecimal {
    static func create(string: String, precision: Int) -> BigDecimal? {
        TokenFormatter().number(from: string, precision: precision)
    }
}

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
