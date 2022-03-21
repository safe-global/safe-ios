//
//  PendingWalletActionViewController.swift
//  Multisig
//
//  Created by Vitaly on 14.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class PendingWalletActionViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet weak var walletImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    var onCancel: () -> Void = {}
    
    var wallet: WCAppRegistryEntry!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placeholder = UIImage(named: "ico-wallet-placeholder")
        walletImage.setImage(
            url: wallet.imageMediumUrl,
            placeholder: placeholder,
            failedImage: placeholder
        )
        titleLabel.setStyle(.primary)
        cancelButton.setText("Cancel", .plain)
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        // needed to react to the "swipe down" to close the modal screen
        parent?.presentationController?.delegate = self
    }

    override func closeModal() {
        didTapCancel(self)
    }

    // Called when user swipes down the modal screen
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        didTapCancel(self)
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        onCancel()
    }
}
