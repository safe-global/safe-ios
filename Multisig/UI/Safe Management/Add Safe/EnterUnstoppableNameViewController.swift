//
//  EnterUnstoppableNameViewController.swift
//  Multisig
//
//  Created by Johnny Good on 4/21/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterUnstoppableNameViewController: UIViewController {
    var onConfirm: () -> Void = { }
    var manager: BlockchainDomainManager!
    var chain: SCGModels.Chain!
    var address: Address?
    var trackingParameters: [String: Any]?

    // generated "task" ID to work around the asynchronous ENS resolving API
    private var currentResolutionTaskID: UUID?
    private var confirmButton: UIBarButtonItem!
    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var textField: GNOTextField!
    @IBOutlet private weak var addressFoundStackView: UIStackView!
    @IBOutlet private weak var foundHeaderLabel: UILabel!
    @IBOutlet private weak var foundIdenticonView: UIImageView!
    @IBOutlet private weak var foundAddressLabel: UILabel!

    convenience init(manager: BlockchainDomainManager, chain: SCGModels.Chain) {
        self.init()
        self.manager = manager
        self.chain = chain
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Enter Unstoppable Name"

        confirmButton = UIBarButtonItem(title: "Confirm", style: .done, target: self, action: #selector(didTapConfirmButton))
        confirmButton.isEnabled = false
        navigationItem.rightBarButtonItem = confirmButton

        textField.setPlaceholder("Enter Unstoppable name")
        textField.textField.autocorrectionType = .no
        textField.textField.autocapitalizationType = .none
        textField.textField.keyboardType = .URL
        textField.textField.delegate = self
        textField.textField.becomeFirstResponder()

        addressFoundStackView.isHidden = true
        foundHeaderLabel.setStyle(.headline)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.safeAddUd, parameters: trackingParameters)
    }

    @objc private func didTapConfirmButton() {
        onConfirm()
    }

    fileprivate func resolveUnstoppableName() {
        cancelResolving()
        textField.setError(nil)
        addressFoundStackView.isHidden = true
        activityIndicator.stopAnimating()
        confirmButton.isEnabled = false
        self.address = nil

        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return
        }

        let taskID = UUID()
        didStartResolving(taskID)
        activityIndicator.startAnimating()

        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            do {
                let address = try self.manager.resolveUD(text)

                if self.isCancelled(taskID) { return }

                DispatchQueue.main.async { [weak self] in
                    self?.onSuccess(address)
                }
            } catch {
                if self.isCancelled(taskID) { return }

                DispatchQueue.main.async { [weak self] in
                    self?.onError(error)
                }
            }
        }
    }

    private func onSuccess(_ address: Address) {
        activityIndicator.stopAnimating()
        foundIdenticonView.setAddress(address.hexadecimal)
        foundAddressLabel.attributedText = (chain.prefixString + address.checksummed).highlight(prefix: chain.prefixString.count + 6)
        addressFoundStackView.isHidden = false
        confirmButton.isEnabled = true
        self.address = address
    }

    private func onError(_ error: Error) {
        activityIndicator.stopAnimating()
        textField.setError(error)
    }

    // pseudo-cancellation (i.e. just ignore current task results)
    // because the resolving API is synchronous.
    private func didStartResolving(_ taskID: UUID) {
        currentResolutionTaskID = taskID
    }

    private func isCancelled(_ taskID: UUID) -> Bool {
        currentResolutionTaskID != taskID
    }

    private func cancelResolving() {
        currentResolutionTaskID = nil
    }
}

extension EnterUnstoppableNameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.resolveUnstoppableName()
        })
        return true
    }
}
