//
//  WCEditParametersViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class WCEditParametersViewController: UIViewController, ExternalURLSource {
    @IBOutlet private weak var nonceLabel: UILabel!
    @IBOutlet private weak var nonceTextField: GNOTextField!
    @IBOutlet private weak var safeTxGasLabel: UILabel!
    @IBOutlet private weak var safeTxGasTextField: GNOTextField!
    @IBOutlet private weak var helpArticleLinkLabel: UILabel!
    @IBOutlet private weak var helpArticleButton: UIButton!

    private var saveButton: UIBarButtonItem!
    private var nonce: UInt256String!
    private var minimalNonce: UInt256!
    // should be nil for contracts of v1.3.0 and higher
    private var safeTxGas: UInt256String?
    private var onUpdate: ((UInt256String, UInt256String?) -> Void)!
    private var trackingParameters: [String: Any]!

    var url: URL? = App.configuration.help.desktopPairingURL

    @IBAction private func openHelpArticle(_ sender: Any) {
        openExternalURL()
    }

    static func create(nonce: UInt256String,
                       minimalNonce: UInt256,
                       safeTxGas: UInt256String?,
                       trackingParameters: [String: Any],
                       onUpdate: @escaping (UInt256String, UInt256String?) -> Void) -> WCEditParametersViewController {
        let controller = WCEditParametersViewController()
        controller.nonce = nonce
        controller.minimalNonce = minimalNonce
        controller.safeTxGas = safeTxGas
        controller.trackingParameters = trackingParameters
        controller.onUpdate = onUpdate
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Transaction"

        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(CloseModal.closeModal))
        navigationItem.leftBarButtonItem = closeButton

        saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem = saveButton

        nonceLabel.setStyle(.callout)
        nonceTextField.textField.text = nonce.description
        nonceTextField.textField.addTarget(self, action: #selector(validateInputs), for: .editingChanged)

        if let safeTxGas = safeTxGas {
            safeTxGasLabel.setStyle(.callout)
            safeTxGasTextField.textField.text = safeTxGas.description
            safeTxGasTextField.textField.addTarget(self, action: #selector(validateInputs), for: .editingChanged)
        } else {
            safeTxGasLabel.isHidden = true
            safeTxGasTextField.isHidden = true
        }

        helpArticleLinkLabel.hyperLinkLabel(linkText: "More on advanced parameters")
        helpArticleButton.setTitle("", for: .normal)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.walletConnectEditParameters, parameters: trackingParameters)
    }

    @objc private func save() {
        guard let nonce = nonce else { return }
        onUpdate(nonce, safeTxGas)
        dismiss(animated: true)
    }

    @objc private func validateInputs() {
        saveButton.isEnabled = false
        guard let nonceText = nonceTextField.textField.text?
                .trimmingCharacters(in: .whitespacesAndNewlines), !nonceText.isEmpty,
              let nonce = UInt256(nonceText), nonce >= minimalNonce else {
            return
        }
        self.nonce = UInt256String(nonce)
        if self.safeTxGas == nil {
            saveButton.isEnabled = true
            return
        }

        if let safeTxGasText = safeTxGasTextField.textField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines), !safeTxGasText.isEmpty,
           let safeTxGas = UInt256(safeTxGasText) {

            self.safeTxGas = UInt256String(safeTxGas)
        } else {
            saveButton.isEnabled = false
        }
    }
}
