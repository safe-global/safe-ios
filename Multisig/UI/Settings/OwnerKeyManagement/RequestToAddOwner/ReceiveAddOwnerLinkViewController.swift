//
//  MakeKeyAnOwnerViewController.swift
//  Multisig
//
//  Created by Vitaly on 13.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReceiveAddOwnerLinkViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var addOwnerView: AddOwnerView!
    @IBOutlet weak var infoBoxView: InfoBoxView!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!

    var safe: Safe!
    var owner: Address!
    var onAddOwner: ((Safe, Address) -> ())!
    var onReplaceOwner: ((Safe, Address) -> ())!
    var onReject: (() -> ())!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenOwnerFromLink, parameters: ["add_owner_chain_id" : safe.chain?.id])

        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        titleLabel.setStyle(.title2)
        messageLabel.setStyle(.body)

        // if owner is added
        let ownerKeyInfo = try? KeyInfo.firstKey(address: owner)
        // if there is an address book entry
        let (ownerName, _) = NamingPolicy.name(for: owner,
                                                info: nil,
                                                chainId: safe.chain!.id!)

        var ownerInfo: AddressInfo!
        if let ownerKeyInfo = ownerKeyInfo {
            ownerInfo = AddressInfo(address: ownerKeyInfo.address, name: ownerKeyInfo.name)
            addOwnerView.set(owner: ownerInfo, badgeName: ownerKeyInfo.keyType.badgeName, safe: safe, reqConfirmations: Int(safe.threshold!), ownerCount: safe.ownersInfo?.count ?? 0)

        } else {
            ownerInfo = AddressInfo(address: owner, name: ownerName)
            addOwnerView.set(owner: ownerInfo, badgeName: nil, safe: safe, reqConfirmations: Int(safe.threshold!), ownerCount: safe.ownersInfo?.count ?? 0)
        }

        infoBoxView.setText("Make sure you trust this key before confirming.")
        rejectButton.setText("Reject", .filledError)
        continueButton.setText("Continue...", .filled)
     }

    @IBAction func didTapReject(_ sender: Any) {
        Tracker.trackEvent(.userRejectOwnerFromLink)
        onReject()
    }

    @IBAction func didTapContinue(_ sender: Any) {
        safe.select()

        let add = UIAlertAction(title: "Add new owner", style: .default) { [unowned self] _ in
            onAddOwner(safe, owner)
        }

        let replace = UIAlertAction(title: "Replace owner", style: .default) { [unowned self] _ in
            onReplaceOwner(safe, owner)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .multiplatformActionSheet)
        alertController.addAction(add)
        alertController.addAction(replace)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}
