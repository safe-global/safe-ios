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
    var parameters: AddOwnerRequestParameters!
    var onContinue: (() -> ())!
    var onReject: (() -> ())!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenOwnerFromLink, parameters: ["add_owner_chain_id" : safe.chain?.id])

        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        titleLabel.setStyle(.title5)
        messageLabel.setStyle(.secondary)

        // if owner is added
        let ownerKeyInfo = try? KeyInfo.firstKey(address: parameters.ownerAddress)
        // if there is an address book entry
        let (ownerName, _) = NamingPolicy.name(for: parameters.ownerAddress,
                                                info: nil,
                                                chainId: safe.chain!.id!)

        var ownerInfo: AddressInfo!
        if let ownerKeyInfo = ownerKeyInfo {
            ownerInfo = AddressInfo(address: ownerKeyInfo.address, name: ownerKeyInfo.name)
            addOwnerView.set(owner: ownerInfo, badgeName: ownerKeyInfo.keyType.imageName, safe: safe, reqConfirmations: Int(safe.threshold!), ownerCount: safe.ownersInfo?.count ?? 0)

        } else {
            ownerInfo = AddressInfo(address: parameters.ownerAddress, name: ownerName)
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
        //TODO: select safe from the link before proceeding with add owner flow
        onContinue()
    }
}
