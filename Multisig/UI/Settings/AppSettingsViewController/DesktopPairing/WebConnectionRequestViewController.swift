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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Connection requested"

        // ui wip
        let chain = Chain.mainnetChain()
        ribbonView.update(chain: chain)

        // if we have owners to select from, show selector
        // otherwise show the 'add first key'
            // after adding, show the selector with the added key.

        chooseOwnerKeyVC = ChooseOwnerKeyViewController(
            owners: [],
            chainID: nil,
            descriptionText: "Gnosis Safe requests to connect to your key",
            requestsPasscode: false,
            selectedKey: nil,
            balancesLoader: nil,
            completionHandler: nil
        )
        addFirstKeyVC = AddOwnerFirstViewController()
        viewControllers = [chooseOwnerKeyVC, addFirstKeyVC]

        displayChild(at: 0, in: contentView)

        closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        navigationItem.leftBarButtonItem = closeButton
    }

    @objc func didTapCloseButton() {

    }
}
