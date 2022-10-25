//
//  LedgerPedingConfirmationViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerPendingConfirmationViewController: UIViewController {
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var safeTxHashLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    var onClose: (() -> Void)?
    var onSign: ((String?, String?) -> Void)?

    var onTxSign: ((Result<(v: UInt8, r: Data, s: Data), Error>) -> Void)?

    private var headerText = "Confirm Transaction"
    private var ledgerHash: String!

    private var ledgerController: LedgerController!
    private var deviceId: UUID!
    private var derivationPath: String!

    private var signRequest: SignRequest!

    @IBAction private func cancel(_ sender: Any) {
        close()
    }

    convenience init(headerText: String? = nil, bluetoothController: BaseBluetoothController, signRequest: SignRequest, deviceId: UUID, derivationPath: String) {
        self.init(nibName: nil, bundle: nil)
        self.ledgerHash = ledgerHash
        if let headerText = headerText {
            self.headerText = headerText
        }
        ledgerController = LedgerController(bluetoothController: bluetoothController)
        self.signRequest = signRequest

        switch signRequest.payload {
        case .hash(let hexToSign):
            self.ledgerHash = Data(hex: hexToSign).sha256().toHexString().uppercased()

        case .rawTx:
            self.ledgerHash = nil
        }

        self.deviceId = deviceId
        self.derivationPath = derivationPath
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onClose?()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // round top corners
        bottomView.layer.cornerRadius = 8
        bottomView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

        headerLabel.text = headerText
        headerLabel.setStyle(.headline)
        descriptionLabel.setStyle(.callout)

        switch signRequest.payload {
        case .hash:
            safeTxHashLabel.attributedText = highlightedLedgerHash

        case .rawTx:
            safeTxHashLabel.text = nil
            descriptionLabel.text = "Please confirm the transaction on your Ledger Nano X."
        }

        cancelButton.setText("Cancel", .plain)

        sign()
    }

    private func sign() {
        switch signRequest.payload {
        case .hash(let hexToSign):
            ledgerController!.sign(messageHash: hexToSign,
                                   deviceId: deviceId,
                                   path: derivationPath) { [weak self] signature, error in
                self?.onSign?(signature, error)
            }
        case let .rawTx(data: data, chainId: chainId, isLegacy: isLegacy):
            ledgerController!.sign(
                chainId: chainId,
                isLegacy: isLegacy,
                rawTransaction: data,
                deviceId: deviceId,
                path: derivationPath) { [weak self] result in
                    self?.onTxSign?(result)
                }
        }
    }

    private func close() {
        dismiss(animated: true)
    }

    var highlightedLedgerHash: NSAttributedString {
        let value = ledgerHash!
        let style = GNOTextStyle.bodyTertiary
        let attributedString = NSMutableAttributedString(
            string: value,
            attributes: [
                .font: UIFont.gnoFont(forTextStyle: style),
                .foregroundColor: style.color!,
                .kern: -0.41
            ]
        )
        // first 4 digits
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.labelPrimary, range: NSRange(location: 0, length: 4))
        // last 4 digits
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.labelPrimary, range: NSRange(location: value.count - 4, length: 4))
        return attributedString
    }
}
