//
//  ReviewExecutionViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Ethereum
import SwiftCryptoTokenFormatter

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

    private var defaultKeyTask: URLSessionTask?
    private var txEstimationTask: URLSessionTask?

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
        contentVC.model = ExecutionReviewUIModel(
            transaction: transaction,
            executionOptions: ExecutionOptionsUIModel(
                accountState: .loading,
                feeState: .loading
            )
        )
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

        findDefaultKey()
        estimateTransaction()
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
        let balancesLoader = DefaultAccountBalanceLoader(chain: chain)

        let keyPickerVC = ChooseOwnerKeyViewController(
            owners: keys,
            chainID: controller.chainId,
            titleText: "Select an execution key",
            descriptionText: "The selected key will be used to execute this transaction.",
            requestsPasscode: false,
            selectedKey: controller.selectedKey?.key,
            balancesLoader: balancesLoader
        )
        // this way of returning the results from the view controller is just because
        // there was already existing code depending on the completion handler.
        // modified with minimum changes to the existing API.
        let completion: (KeyInfo?) -> Void = { [weak self, weak keyPickerVC] selectedKeyInfo in
            guard let self = self, let picker = keyPickerVC else { return }
            let balance = selectedKeyInfo.flatMap { picker.accountBalance(for: $0) }

            // update selection
            if let key = selectedKeyInfo, let balance = balance {
                self.controller.selectedKey = (key, balance)
            } else {
                self.controller.selectedKey = nil
            }
            self.didChangeSelectedKey()

            self.dismiss(animated: true)
        }
        keyPickerVC.completionHandler = completion

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
        let advancedVC = AdvancedTransactionDetailsViewController(transaction, chain: chain)
        show(advancedVC, sender: self)
    }

    @IBAction func didTapSubmit(_ sender: Any) {
        print("Submit!")
    }

    func findDefaultKey() {
        defaultKeyTask?.cancel()

        self.contentVC.model?.executionOptions.accountState = .loading

        let task = controller.findDefaultKey { [weak self] in
            self?.didChangeSelectedKey()
        }

        self.defaultKeyTask = task
    }

    func didChangeSelectedKey() {
        if let selection = controller.selectedKey {
            let model = MiniAccountInfoUIModel(
                prefix: self.chain.shortName,
                address: selection.key.address,
                label: selection.key.name,
                imageUri: nil,
                badge: selection.key.keyType.imageName,
                balance: selection.balance.displayAmount
            )
            self.contentVC.model?.executionOptions.accountState = .filled(model)
        } else {
            contentVC.model?.executionOptions.accountState = .empty
        }

        // we should reestimate (again) after changing the key.
        estimateTransaction()
    }

    func estimateTransaction() {
        txEstimationTask?.cancel()

        contentVC.model?.executionOptions.feeState = .loading

        let task = controller.estimate { [weak self] error in
            // TODO: display estimation error
            self?.didChangeEstimation()
        }

        txEstimationTask = task
    }

    func didChangeEstimation() {
        if let tx = controller.ethTransaction {

            let feeInWei = tx.totalFee

            let nativeCoinDecimals = chain.nativeCurrency!.decimals
            let nativeCoinSymbol = chain.nativeCurrency!.symbol!

            let decimalAmount = BigDecimal(Int256(feeInWei.big()), Int(nativeCoinDecimals))
            let value = TokenFormatter().string(
                from: decimalAmount,
                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                forcePlusSign: false
            )

            let tokenAmount: String = "\(value) \(nativeCoinSymbol)"

            // TODO: fetch fiat amount

            let model = EstimatedFeeUIModel(
                tokenAmount: tokenAmount,
                fiatAmount: nil)

            contentVC.model?.executionOptions.feeState = .loaded(model)
        } else {
            contentVC.model?.executionOptions.feeState = .empty
        }
    }
}
