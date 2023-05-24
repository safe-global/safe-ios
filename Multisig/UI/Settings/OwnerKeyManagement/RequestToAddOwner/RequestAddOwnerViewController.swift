//
//  RequestAddOwnerViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class RequestAddOwnerViewController: UIViewController {
    @IBOutlet weak var safeInfoView: AddressInfoView!
    @IBOutlet weak var ownerInfoView: AddressInfoView!
    @IBOutlet weak var closeButton: UIButton!

    var safe: Safe!
    var parameters: AddOwnerRequestParameters!

    var onDone: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        safeInfoView.setTitle("Safe Account")
        safeInfoView.setAddress(safe.addressValue, label: safe.name, prefix: safe.chain!.shortName)

        ownerInfoView.setTitle("New Owner")
        ownerInfoView.setAddress(parameters.ownerAddress)

        closeButton.setText("Close", .filled)

        // NOTE: Safe Account can be not selected! when making any operation, make the Safe Account selected
        // if that's needed by the user flow.
    }

    @IBAction func didTapClose(_ sender: Any) {
        onDone()
    }

}
