//
//  ReviewExecutionViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

// wrapper around the content
class ReviewExecutionViewController: ContainerViewController {

    private var safe: Safe!
    private var chain: Chain!
    private var transaction: SCGModels.TransactionDetails!

    private var onClose: () -> Void = { }

    private var contentVC: ReviewExecutionContentViewController!

    @IBOutlet weak var ribbonView: RibbonView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var submitButton: UIButton!

    var closeButton: UIBarButtonItem!

    convenience init(safe: Safe, chain: Chain, transaction: SCGModels.TransactionDetails, onClose: @escaping () -> Void) {
        // create from the nib named as the self's class name
        self.init(namedClass: nil)
        self.safe = safe
        self.chain = chain
        self.transaction = transaction
        self.onClose = onClose
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(safe != nil)
        assert(chain != nil)
        assert(transaction != nil)

        title = "Execute"

        // configure content
        contentVC = ReviewExecutionContentViewController(
            safe: safe,
            chain: chain,
            transaction: transaction)
        self.viewControllers = [contentVC]
        self.displayChild(at: 0, in: contentView)

        // configure ribbon view
        ribbonView.update(chain: chain)

        // configure submit button
        submitButton.setText("Submit", .filled)

        // configure close button
        closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose(_:)))

        navigationItem.leftBarButtonItem = closeButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // tracking
    }

    @IBAction func didTapSubmit(_ sender: Any) {
        print("Submit!")
    }

    @IBAction func didTapClose(_ sender: Any) {
        self.onClose()
    }
}
