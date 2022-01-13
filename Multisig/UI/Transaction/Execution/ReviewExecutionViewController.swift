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

    private var controller: TransactionExecutionController!

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
        self.controller = TransactionExecutionController(safe: safe, chain: chain, transaction: transaction)
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
        contentVC.onTapAccount = action(#selector(didTapAccount(_:)))
        contentVC.onTapFee = action(#selector(didTapFee(_:)))
        contentVC.onTapAdvanced = action(#selector(didTapAdvanced(_:)))

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

    func action(_ selector: Selector) -> () -> Void {
        { [weak self] in
            self?.performSelector(onMainThread: selector, with: nil, waitUntilDone: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // tracking
    }


    @IBAction func didTapClose(_ sender: Any) {
        self.onClose()
    }

    @IBAction func didTapAccount(_ sender: Any) {
        let keys = controller.executionKeys()
        let selectedIndex = controller.selectedKeyIndex
        let balancesLoader = DefaultAccountBalanceLoader(chain: chain)

        let keyPickerVC = ChooseOwnerKeyViewController(
            owners: keys,
            chainID: controller.chainId,
            titleText: "Select an execution key",
            descriptionText: "The selected key will be used to execute this transaction.",
            requestsPasscode: false,
            selectedIndex: selectedIndex,
            balancesLoader: balancesLoader
        ) { [weak self] selectedKeyInfo in
            // dismiss
            guard let self = self else { return }
            self.dismiss(animated: true) {
                // when dismissed, change the selected key
                if let keyInfo = selectedKeyInfo {
                    print(keyInfo)
                } else {
                    print("nothing selected")
                }
            }
        }

        let navigationController = UINavigationController(rootViewController: keyPickerVC)
        present(navigationController, animated: true)
    }

    @IBAction func didTapFee(_ sender: Any) {
        let formModel = FeeLegacyFormModel(
            nonce: 22,
            gas: 53000,
            gasPriceInWei: 12,
            nativeCurrency: chain.nativeCurrency!)
        let formVC = FormViewController(model: formModel) { [weak self] in
            // on close
            self?.dismiss(animated: true, completion: {
                // update estimation parameters, etc.
            })
        }
        formVC.navigationItem.title = "Edit transaction fee"

        let nav = UINavigationController(rootViewController: formVC)
        present(nav, animated: true, completion: nil)
    }

    @IBAction func didTapAdvanced(_ sender: Any) {
        print("Advanced!")
    }

    @IBAction func didTapSubmit(_ sender: Any) {
        print("Submit!")
    }
}
