//
//  EnterSafeAddressViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import Web3

class EnterSafeAddressViewController: UIViewController {
    var websiteURL = App.configuration.services.webAppURL
    var address: Address? { addressField?.address }
    var transactionService = App.shared.safeTransactionService
    var completion: () -> Void = { }

    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var addressField: AddressField!
    @IBOutlet private weak var actionStackView: UIStackView!
    @IBOutlet private weak var actionLabel: UILabel!
    @IBOutlet private weak var openWebsiteButton: UIButton!
    @IBOutlet private weak var externalLinkIcon: UIImageView!
    @IBOutlet private weak var suggestionStackView: UIStackView!

    private var loadSafeTask: URLSessionTask?
    private var nextButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Load Safe Multisig"

        headerLabel.setStyle(.headline)

        actionLabel.setStyle(.primary)

        addressField.setPlaceholderText("Enter Safe address")
        addressField.onTap = { [weak self] in self?.didTapAddressField() }

        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        nextButton.isEnabled = false

        navigationItem.rightBarButtonItem = nextButton

        openWebsiteButton.setText(websiteURL.absoluteString, .plain)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.safeAddAddress)
    }

    @IBAction private func didTapOpenWebsiteButton(_ sender: Any) {
        openInSafari(websiteURL)
    }

    @objc private func didTapNextButton(_ sender: Any) {
        guard let address = address else { return }
        let vc = EnterAddressNameViewController()
        vc.address = address
        vc.trackingEvent = .safeAddName
        vc.screenTitle = "Load Safe Multisig"
        vc.descriptionText = "Choose a name for the Safe. The name is only stored locally and will not be shared with Gnosis or any third parties."
        vc.actionTitle = "Next"
        vc.placeholder = "Enter name"
        vc.completion = { [unowned vc, unowned self] name in
            Safe.create(address: address.checksummed, name: name)
            if !AppSettings.hasShownImportKeyOnboarding && !PrivateKeyController.hasPrivateKey {
                let safeLoadedViewController = SafeLoadedViewController()
                safeLoadedViewController.completion = self.completion
                safeLoadedViewController.hidesBottomBarWhenPushed = true
                vc.show(safeLoadedViewController, sender: vc)
                AppSettings.hasShownImportKeyOnboarding = true
            } else {
                self.completion()
            }
        }
        show(vc, sender: self)
    }

    private func didTapAddressField() {
        let vc = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        vc.addAction(UIAlertAction(title: "Paste from Clipboard", style: .default, handler: { [weak self] _ in
            let text = Pasteboard.string
            self?.didEnterText(text)
        }))

        vc.addAction(UIAlertAction(title: "Scan QR Code", style: .default, handler: { [weak self] _ in
            let vc = QRCodeScannerViewController()
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.setup()
            self?.present(vc, animated: true, completion: nil)
        }))

        vc.addAction(UIAlertAction(title: "Enter ENS Name", style: .default, handler: { [weak self] _ in
            let vc = EnterENSNameViewController()
            vc.onConfirm = { [weak self] in
                guard let `self` = self else { return }
                self.navigationController?.popViewController(animated: true)
                self.didEnterText(vc.address?.checksummed)
            }
            self?.show(vc, sender: nil)
        }))
        
        vc.addAction(UIAlertAction(title: "Enter Unstoppable Name", style: .default, handler: { [weak self] _ in
            let vc = EnterUnstoppableNameViewController()
            vc.onConfirm = { [weak self] in
                guard let `self` = self else { return }
                self.navigationController?.popViewController(animated: true)
                self.didEnterText(vc.address?.checksummed)
            }
            self?.show(vc, sender: nil)
        }))

        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(vc, animated: true, completion: nil)
    }

    private func setSuggestionHidden(_ isHidden: Bool) {
        suggestionStackView.isHidden = isHidden
        externalLinkIcon.isHidden = isHidden
    }

    private func didEnterText(_ text: String?) {
        addressField.clear()
        loadSafeTask?.cancel()
        nextButton.isEnabled = false
        setSuggestionHidden(false)

        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }

        setSuggestionHidden(true)

        guard !text.isEmpty else {
            addressField.setError("Safe address should not be empty")
            return
        }
        addressField.setInputText(text)
        do {
            // (1) validate that the text is address
            let address = try Address(text, isERC681: true)
            addressField.setAddress(address)

            // (2) and that there's no such safe already
            let exists = try Safe.exists(address.checksummed)
            if exists { throw GSError.SafeAlreadyExists() }

            // (3) and there exists safe at that address
            addressField.setLoading(true)
            loadSafeTask = transactionService.asyncSafeInfo(at: address, completion: { [weak self] result in
                DispatchQueue.main.async {
                    self?.addressField.setLoading(false)
                }
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        // ignore cancellation error due to cancelling the
                        // currently running task. Otherwise user will see
                        // meaningless message.
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            return
                        } else if error is GSError.EntityNotFound {
                            let message = GSError.error(description: "Can’t use this address",
                                                        error: GSError.InvalidSafeAddress()).localizedDescription
                            self.addressField.setError(message)
                        } else {
                            let message = GSError.error(description: "Can’t use this address", error: error)
                            self.addressField.setError(message)
                        }
                    }
                case .success(let info):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }

            // (4) and its mastercopy is supported
                        let implementation = info.implementation.address
                        guard App.shared.gnosisSafe.isSupported(implementation) else {
                            let error = GSError.error(description: "Can’t use this address",
                                                      error: GSError.UnsupportedImplementationCopy())
                            self.addressField.setError(error.localizedDescription)
                            return
                        }
                        self.nextButton.isEnabled = true
                    }
                }
            })
        } catch {
            addressField.setError(
                GSError.error(description: "Can’t use this address",
                              error: error is EthereumAddress.Error ? GSError.SafeAddressNotValid() : error))
        }
    }
}

extension EnterSafeAddressViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }

    func scannerViewControllerDidScan(_ code: String) {
        didEnterText(code)
        dismiss(animated: true, completion: nil)
    }
}
