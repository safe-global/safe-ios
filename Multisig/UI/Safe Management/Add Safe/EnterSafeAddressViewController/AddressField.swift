//
//  AddressField.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddressField: UINibView {
    var onTap: () -> Void = { }
    private(set) var text: String?
    private(set) var address: Address?
    private(set) var error: Error?

    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var inputLabel: UILabel!
    @IBOutlet private var addressView: AddressInfoView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var ellipsis: UIImageView!
    @IBOutlet private var borderView: UIImageView!
    @IBOutlet private var errorLabel: UILabel!
    @IBOutlet private weak var rightStackView: UIStackView!
    @IBOutlet private weak var inputStackView: UIStackView!
    @IBOutlet private weak var fieldBackgroundView: UIView!

    override func commonInit() {
        super.commonInit()
        placeholderLabel.setStyle(.bodyTertiary)
        inputLabel.setStyle(.body)
        errorLabel.setStyle(.calloutError)

        ellipsis.tintColor = .labelTertiary

        setPlaceholderText(nil)
        setInputText(nil)
        setError(nil)
        setLoading(false)
    }

    func setPlaceholderText(_ text: String?) {
        placeholderLabel.text = text
    }

    func setInputText(_ text: String?) {
        self.text = text
        if let text = text, !text.isEmpty {
            inputLabel.text = text
            showInputView(inputLabel)
        } else {
            showInputView(placeholderLabel)
        }
    }

    func setAddress(_ address: Address?, label: String? = nil, prefix: String? = nil) {
        self.address = address
        if let address = address {
            addressView.setAddress(address, label: label, prefix: prefix)
            showInputView(addressView)
            borderView.tintColor = .borderSelected
        } else {
            showInputView(placeholderLabel)
        }
    }

    private func showInputView(_ view: UIView) {
        for view in inputStackView.arrangedSubviews {
            inputStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        inputStackView.addArrangedSubview(view)
    }

    private func showRightView(_ view: UIView) {
        for view in rightStackView.arrangedSubviews {
            rightStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        rightStackView.addArrangedSubview(view)
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            showRightView(activityIndicator)
        } else {
            showRightView(ellipsis)
        }
    }

    func setError(_ error: Error?) {
        self.error = error
        if let error = error {
            errorLabel.text = error.localizedDescription
            borderView.tintColor = .error
            errorLabel.isHidden = false
        } else {
            borderView.tintColor = .border
            errorLabel.text = nil
            errorLabel.isHidden = true
        }
    }

    func clear() {
        setInputText(nil)
        setAddress(nil)
        setError(nil)
        setLoading(false)
    }

    @IBAction func didTapField(_ sender: Any) {
        onTap()
    }

    @IBAction func didTouchUp(_ sender: Any) {
        fieldBackgroundView.alpha = 1.0
    }

    @IBAction func didTouchDown(_ sender: Any) {
        fieldBackgroundView.alpha = 0.7
    }

}
