//
//  WCEditParametersViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class WCEditParametersViewController: UIViewController {
    @IBOutlet private weak var nonceLabel: UILabel!
    @IBOutlet private weak var nonceTextField: GNOTextField!
    @IBOutlet private weak var safeTxGasLabel: UILabel!
    @IBOutlet private weak var safeTxGasTextField: GNOTextField!

    private var saveButton: UIBarButtonItem!
    private var nonce: UInt256String!
    private var minimalNonce: UInt256String!
    private var safeTxGas: UInt256String!
    private var onUpdate: ((UInt256String, UInt256String) -> Void)!

    private let blockGasLimit = 15_000_000

    static func create(nonce: UInt256String,
                       minimalNonce: UInt256String,
                       safeTxGas: UInt256String,
                       onUpdate: @escaping (UInt256String, UInt256String) -> Void) -> WCEditParametersViewController {
        let controller = WCEditParametersViewController(nibName: "WCEditParametersViewController", bundle: Bundle.main)
        controller.nonce = nonce
        controller.minimalNonce = minimalNonce
        controller.safeTxGas = safeTxGas
        controller.onUpdate = onUpdate
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Transaction"

        saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem = saveButton

        nonceLabel.setStyle(.headline)
        safeTxGasLabel.setStyle(.headline)

        nonceTextField.textField.text = nonce.description
        nonceTextField.textField.addTarget(self, action: #selector(validateInputs), for: .editingChanged)

        safeTxGasTextField.textField.text = safeTxGas.description
        safeTxGasTextField.textField.addTarget(self, action: #selector(validateInputs), for: .editingChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.walletConnectEditParameters)
    }

    @objc private func save() {
        guard let nonce = nonce, let safeTxGas = safeTxGas else { return }
        onUpdate(nonce, safeTxGas)
        navigationController?.popViewController(animated: true)
    }

    @objc private func validateInputs() {
        saveButton.isEnabled = false
        guard let nonceText = nonceTextField.textField.text?
                .trimmingCharacters(in: .whitespacesAndNewlines), !nonceText.isEmpty,
              let nonce = UInt256(nonceText), nonce >= minimalNonce.value,
              let safeTxGasText = safeTxGasTextField.textField.text?
                .trimmingCharacters(in: .whitespacesAndNewlines), !safeTxGasText.isEmpty,
              let safeTxGas = UInt256(safeTxGasText), safeTxGas <= blockGasLimit else {
            return
        }
        self.nonce = UInt256String(nonce)
        self.safeTxGas = UInt256String(safeTxGas)
        saveButton.isEnabled = true
    }
}
