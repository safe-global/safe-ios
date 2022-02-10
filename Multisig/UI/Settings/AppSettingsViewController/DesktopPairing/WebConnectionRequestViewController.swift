//
//  WebConnectionRequestViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WebConnectionRequestViewController: ContainerViewController {
    @IBOutlet weak var ribbonView: RibbonView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var actionPanelView: ActionPanelView!

    var closeButton: UIBarButtonItem!
    var chooseOwnerKeyVC: ChooseOwnerKeyViewController!
    var addFirstKeyVC: AddOwnerFirstViewController!

    // set from outside
    var connectionController: WebConnectionController!
    var connection: WebConnection!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Connection requested"

//        ribbonView.update(chain: controller.chain(for: connectionURL))

        let keys = connectionController.accountKeys()
        if keys.isEmpty {
            showAddFirstKey()
        } else {
            showKeyPicker()
        }

        closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        navigationItem.leftBarButtonItem = closeButton
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
        chooseOwnerKeyVC = ChooseOwnerKeyViewController(
                owners: [], // keys,
                chainID: nil,
                descriptionText: "Gnosis Safe requests to connect to your key",
                requestsPasscode: false,
                selectedKey: nil,
                balancesLoader: nil
        )  { selectedKey in

        }
        viewControllers = [chooseOwnerKeyVC]
        displayChild(at: 0, in: contentView)
    }

    @objc func didTapCloseButton() {

    }
}
