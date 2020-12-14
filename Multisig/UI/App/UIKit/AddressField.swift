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

    @IBOutlet private weak var placeholderLabel: UILabel!
    @IBOutlet private weak var inputLabel: UILabel!
    @IBOutlet private weak var addressView: AddressInfoView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var ellipsis: UIImageView!
    @IBOutlet private weak var borderView: UIImageView!
    @IBOutlet private weak var errorLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        errorLabel.setStyle(GNOTextStyle.callout.color(.gnoTomato))
        inputLabel.setStyle(.body)
        placeholderLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))

        ellipsis.tintColor = .gnoMediumGrey

        setPlaceholderText(nil)
        setInputText(nil)
        setLoading(false)
    }

    func setPlaceholderText(_ text: String?) {
        placeholderLabel.text = text
    }

    func setInputText(_ text: String?) {
        self.text = text
        address = nil
        setError(nil)

        if let text = text, !text.isEmpty {
            do {
                let address = try Address(from: text)
                addressView.setAddress(address, label: nil)
                showContentViews([addressView])
                self.address = address
            } catch {
                setError(error)
                inputLabel.text = text
                showContentViews([errorLabel, inputLabel])
            }
        } else {
            showContentViews([placeholderLabel])
        }
    }

    private func showContentViews(_ views: Set<UIView>) {
        let contentViews = Set<UIView>([
            placeholderLabel,
            inputLabel,
            addressView,
            errorLabel
        ])
        views.forEach {
            $0.isHidden = false
        }
        contentViews.subtracting(views).forEach {
            $0.isHidden = true
        }
    }

    private func showRightView(_ view: UIView) {
        let views = Set<UIView>([activityIndicator, ellipsis])
        view.isHidden = false
        views.subtracting([view]).forEach { $0.isHidden = true }
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            showRightView(activityIndicator)
        } else {
            showRightView(ellipsis)
        }
    }

    func setError(_ error: Error?) {
        if let error = error {
            errorLabel.text = error.localizedDescription
            borderView.tintColor = .gnoTomato
            errorLabel.isHidden = false
        } else {
            borderView.tintColor = .gnoMediumGrey
            errorLabel.text = nil
            errorLabel.isHidden = true
        }
    }

    @IBAction func didTapField(_ sender: Any) {
        onTap()
    }

}
