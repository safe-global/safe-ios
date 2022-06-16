//
//  ValidateRequestToAddOwnerViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ValidateRequestToAddOwnerViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!

    var parameters: AddOwnerRequestParameters!
    var onContinue: () -> Void = { }
    var onCancel: () -> Void = { }

    private var safeLoader = SafeInfoLoader()

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        descriptionLabel.setStyle(.primary)

        cancelButton.setText("Cancel", .plain)

        validate()
    }

    override func closeModal() {
        cancel()
    }

    @IBAction func didTapCancelButton(_ sender: Any) {
        cancel()
    }

    func validate() {
        safeLoader = SafeInfoLoader()
        safeLoader.load(chain: parameters.chain, safe: parameters.safeAddress) { [weak self] result in
            self?.handle(result: result)
        }
    }

    func revalidate() {
        // come back to the verification screen
        // verify again with the same parameters
        navigationController?.popToRootViewController(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [unowned self] in
            validate()
        }
    }

    func handle(result: Result<SCGModels.SafeInfoExtended, Error>) {
        do {
            let info = try result.get()

            let isAlreaydAnOwner = info.owners.contains(where: { $0.addressInfo.address == parameters.ownerAddress })
            if isAlreaydAnOwner {
                handleOwnerAlreadyInOwnerList()
                return
            }

            // do we have such a safe?
            guard let safe = Safe.by(address: parameters.safeAddress.checksummed, chainId: parameters.chain.id!) else {
                handleSafeNotAdded(info: info)
                return
            }

            // update database
            safe.update(from: info)

            if safe.isReadOnly {
                handleSafeReadOnly()
                return
            }

            // all requirements passed
            handleValidationSuccess(safe: safe)

        } catch {
            // show error screen
            let errorVC = InactiveLinkViewController.broken(error, completion: onCancel)
            show(errorVC, sender: self)
        }
    }

    func handleOwnerAlreadyInOwnerList() {
        let inactiveLinkVC = InactiveLinkViewController.inactiveLink(completion: onCancel)
        show(inactiveLinkVC, sender: self)
    }

    func handleSafeNotAdded(info: SCGModels.SafeInfoExtended) {
        // safe must be added to the app to continue
        let noSafeVC = AddOwnerExceptionViewController.safeNotFound(
            address: parameters.safeAddress,
            chain: parameters.chain,
            onAdd: { [unowned self] in
                // add safe
                Safe.create(
                    address: parameters.safeAddress.checksummed,
                    version: info.version,
                    name: "Safe",
                    chain: parameters.chain
                )

                App.shared.notificationHandler.safeAdded(address: parameters.safeAddress)

                // re-trigger validation
                revalidate()
            },
            onClose: onCancel)
        show(noSafeVC, sender: self)
    }

    func handleSafeReadOnly() {
        // if safe is read-only then can't add new owner.

        let readOnlyVC = AddOwnerExceptionViewController.safeReadOnly(
            address: parameters.safeAddress,
            chain: parameters.chain,
            onAdd: { [unowned self] in
                // add new owner
                let addOwnerVC = ViewControllerFactory.addOwnerViewController { [weak self] in
                    // owner added, close opened screen.
                    self?.dismiss(animated: true) {
                        // re-trigger validation
                        self?.revalidate()
                    }
                }

                // start adding owner
                present(addOwnerVC, animated: true)
            },
            onClose: onCancel
        )
        show(readOnlyVC, sender: self)
    }

    func handleValidationSuccess(safe: Safe) {
        // show the 'receive' screen
        let requestVC = ReceiveAddOwnerLinkViewController()
        requestVC.safe = safe
        requestVC.parameters = parameters
        requestVC.onContinue = onContinue
        requestVC.onReject = onCancel
        show(requestVC, sender: self)
    }

    func cancel() {
        safeLoader.cancel()
        onCancel()
    }

}
