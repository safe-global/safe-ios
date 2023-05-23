//
//  AddOwnerExceptionViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddOwnerExceptionViewController: UIViewController {

    @IBOutlet weak var ribbonView: RibbonView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var addressContainer: UIView!
    @IBOutlet weak var addressInfoView: AddressInfoView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var notNowButton: UIButton!

    var chain: Chain!
    var address: Address!

    var iconImage: UIImage? = UIImage(named: "ico-no-permission")

    var titleText: String!
    var bodyText: String!

    var addButtonTitle: String!
    var notNowButtonTitle: String = "Not now"

    var onAdd: () -> Void = { }
    var onClose: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.makeTransparentNavigationBar(self)
        ViewControllerFactory.addCloseButton(self)

        iconView.image = iconImage

        ribbonView.update(chain: chain)

        titleLabel.setStyle(.title3.weight(.semibold))
        titleLabel.text = titleText

        bodyLabel.setStyle(.body)
        bodyLabel.text = bodyText

        let (name, image) = NamingPolicy.name(for: address, chainId: chain.id!)
        if let safe = Safe.by(address: address.checksummed, chainId: chain.id!) {
            // TODO: show the required confirmations (n/m) in the identicon
            let ownerCount = safe.ownersInfo?.count ?? 1
            let requiredConfirmations: Int = Int(safe.threshold ?? 1)
            print("Safe \(requiredConfirmations) / \(ownerCount)")
        }
        addressInfoView.setAddress(
            address,
            label: name,
            imageUri: image,
            prefix: chain.shortName
        )

        addButton.setText(addButtonTitle, .filled)
        notNowButton.setText(notNowButtonTitle, .primary)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        addressContainer.layer.borderWidth = 2
        addressContainer.layer.borderColor = UIColor.border.cgColor
        addressContainer.layer.cornerRadius = 8
    }

    override func closeModal() {
        onClose()
    }

    @IBAction func didTapAdd(_ sender: Any) {
        onAdd()
    }

    @IBAction func didTapNotNow(_ sender: Any) {
        onClose()
    }
}

extension AddOwnerExceptionViewController {
    static func safeNotFound(address: Address, chain: Chain, onAdd: @escaping () -> Void, onClose: @escaping () -> Void) -> AddOwnerExceptionViewController {
        let vc = AddOwnerExceptionViewController()
        vc.titleText = "You need to add the Safe to make actions with it"
        vc.bodyText = "Add this Safe first and then connect a signer key that is one of the owners in order to unlock permissions."
        vc.addButtonTitle = "Add this Safe"
        vc.address = address
        vc.chain = chain
        vc.onAdd = onAdd
        vc.onClose = onClose
        return vc
    }

    static func safeReadOnly(address: Address, chain: Chain, onAdd: @escaping () -> Void, onClose: @escaping () -> Void) -> AddOwnerExceptionViewController {
        let vc = AddOwnerExceptionViewController()
        vc.titleText = "You don’t have permissions to modify Safe Account settings"
        vc.bodyText = "Any change in Safe Account settings requires a signer key that is one of the owners.\n\nAdd the signer key first to unlock permissions."
        vc.addButtonTitle = "Add signer key"
        vc.address = address
        vc.chain = chain
        vc.onAdd = onAdd
        vc.onClose = onClose
        return vc
    }
}
