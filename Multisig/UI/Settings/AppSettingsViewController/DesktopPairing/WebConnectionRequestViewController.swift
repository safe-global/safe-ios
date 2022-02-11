//
//  WebConnectionRequestViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WebConnectionRequestViewController: ContainerViewController, UIAdaptivePresentationControllerDelegate {
    @IBOutlet weak var ribbonView: RibbonView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var actionPanelView: ActionPanelView!

    var closeButton: UIBarButtonItem!
    var chooseOwnerKeyVC: ChooseOwnerKeyViewController!
    var addFirstKeyVC: AddOwnerFirstViewController!

    var selectedKey: KeyInfo? {
        chooseOwnerKeyVC?.selectedKey
    }

    var connectionController: WebConnectionController!
    var connection: WebConnection!
    var chain: Chain!

    var onFinish: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Connection requested"

        assert(connection != nil)
        assert(connectionController != nil)
        assert(connection.chainId != nil)

        chain = Chain.by(String(connection.chainId!))!

        ribbonView.update(chain: chain)

        let keys = connectionController.accountKeys()
        if keys.isEmpty {
            showAddFirstKey()
        } else {
            showKeyPicker()
        }
        didUpdateSelection()

        closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        navigationItem.leftBarButtonItem = closeButton

        actionPanelView.onConfirm = { [unowned self] in
            assert(selectedKey != nil)
            connection.accounts = [selectedKey!.address]
            connectionController.userDidApprove(connection)
            onFinish()
        }

        actionPanelView.onReject = { [unowned self] in
            connectionController.userDidReject(connection)
            onFinish()
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        parent?.presentationController?.delegate = self
    }

    func showAddFirstKey() {
        addFirstKeyVC = AddOwnerFirstViewController()
        viewControllers = [addFirstKeyVC]
        displayChild(at: 0, in: contentView)

        addFirstKeyVC.onSuccess = { [weak self] in
            guard let self = self else { return }
            self.navigationController?.popToRootViewController(animated: true)
            self.showKeyPicker()
        }
    }

    func showKeyPicker() {
        let keys = connectionController.accountKeys()
        chooseOwnerKeyVC = ChooseOwnerKeyViewController(
                owners: keys,
                chainID: String(connection.chainId!),
                descriptionText: "Gnosis Safe requests to connect to your key",
                requestsPasscode: false,
                selectedKey: keys.first,
                balancesLoader: nil
        )  { [unowned self] _ in
            didUpdateSelection()
        }
        viewControllers = [chooseOwnerKeyVC]
        displayChild(at: 0, in: contentView)
    }

    func didUpdateSelection() {
        let enabled = selectedKey != nil
        actionPanelView.setConfirmEnabled(enabled)
    }

    @objc func didTapCloseButton() {
        connectionController.userDidCancel(connection)
        onFinish()
    }

    // Called when user swipes down the modal screen
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        connectionController.userDidCancel(connection)
        onFinish()
    }

}
