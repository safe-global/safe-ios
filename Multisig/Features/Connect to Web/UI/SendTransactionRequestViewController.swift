//
// Created by Dmitry Bespalov on 18.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import Ethereum
import Solidity

class SendTransactionRequestViewController: WebConnectionContainerViewController, WebConnectionRequestObserver {

    var controller: WebConnectionController!
    var connection: WebConnection!
    var request: WebConnectionSendTransactionRequest!

    private var transaction: EthTransaction!

    private var contentVC: SendTransactionContentViewController!
    private var balanceLoader: DefaultAccountBalanceLoader!
    private var estimationController: TransactionEstimationController!

    private var fee: UInt256?
    private var balance: UInt256?
    private var error: Error?
    private var minNonce: Sol.UInt64 = 0
    private var userParameters = UserDefinedTransactionParameters()
    private var chain: Chain!

    convenience init() {
        self.init(namedClass: WebConnectionContainerViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Execute Transaction Request"

        chain = controller.chain(for: request)!

        transaction = request.transaction

        balanceLoader = DefaultAccountBalanceLoader(chain: chain)
        let rpcUri = chain.authenticatedRpcUrl.absoluteString
        estimationController = TransactionEstimationController(rpcUri: rpcUri, chain: chain)

        ribbonView.update(chain: chain)

        if let peer = connection.remotePeer {
            headerView.textLabel.text = peer.name
            headerView.detailTextLabel.text = peer.url.host
            let placeholder = UIImage(named: "connection-placeholder")
            headerView.imageView.setImage(url: peer.icons.first, placeholder: placeholder, failedImage: placeholder)
        } else {
            headerView.isHidden = true
        }

        actionPanelView.setConfirmText("Submit")

        controller.attach(observer: self, to: request)

        contentVC = SendTransactionContentViewController()
        viewControllers = [contentVC]
        displayChild(at: 0, in: contentView)

        contentVC.onTapFee = { [unowned self] in
            openFeeEditor()
        }

        reloadData()
        loadBalance()
        estimate()
    }

    deinit {
        controller.detach(observer: self)
    }

    func didUpdate(request: WebConnectionRequest) {
        if request.status == .success || request.status == .failed {
            onFinish()
        }
    }

    override func didCancel() {
        didReject()
    }

    override func didReject() {

    }

    override func didConfirm() {

    }

    func reloadData() {
        guard let keyInfo = try? KeyInfo.firstKey(address: connection.accounts.first!) else { return }
        fee = transaction.totalFee.big()
        contentVC.reloadData(transaction: transaction,
                             keyInfo: keyInfo,
                             chain: chain,
                             balance: balance,
                             fee: fee,
                             error: error?.localizedDescription)
    }

    // load balance for the selected account.
    func loadBalance() {
        guard let keyInfo = try? KeyInfo.firstKey(address: connection.accounts.first!) else { return }
        _ = balanceLoader.loadBalances(for: [keyInfo]) { [weak self] result in
            guard let self = self else { return }
            do {
                let model = try result.get()
                self.balance = model.first?.amount?.big()
                self.reloadData()
            } catch {
                LogService.shared.error("Failed to load balance: \(error)")
            }
        }
    }

    func estimate() {
        self.error = nil
        _ = estimationController.estimateTransactionWithRpc(tx: transaction) { [weak self] result in
            guard let self = self else { return }
            do {
                let results = try result.get()

                let gas = try results.gas.get()
                let _ = try results.ethCall.get()
                let gasPrice = try results.gasPrice.get()
                let txCount = try results.transactionCount.get()
                self.minNonce = txCount
                self.transaction.update(gas: gas, transactionCount: txCount, baseFee: gasPrice)
            } catch {
                LogService.shared.error("Error estimating transaction: \(error)")
                self.error = error
            }
            self.updateEthTransactionWithUserValues()
            self.reloadData()
        }
    }

    // modifying estimation - copy from the review execution (form)
    func openFeeEditor() {
        let formModel: FormModel
        var initialValues = UserDefinedTransactionParameters()

        switch transaction {
        case let ethTx as Eth.TransactionLegacy:
            let model = FeeLegacyFormModel(
                nonce: ethTx.nonce,
                minimalNonce: minNonce,
                gas: ethTx.fee.gas,
                gasPriceInWei: ethTx.fee.gasPrice,
                nativeCurrency: chain.nativeCurrency!
            )
            initialValues.nonce = model.nonce
            initialValues.gas = model.gas
            initialValues.gasPrice = model.gasPriceInWei

            formModel = model

        case let ethTx as Eth.TransactionEip1559:
            let model = Fee1559FormModel(
                nonce: ethTx.nonce,
                minimalNonce: minNonce,
                gas: ethTx.fee.gas,
                maxFeePerGasInWei: ethTx.fee.maxFeePerGas,
                maxPriorityFeePerGasInWei: ethTx.fee.maxPriorityFee,
                nativeCurrency: chain.nativeCurrency!
            )
            initialValues.nonce = model.nonce
            initialValues.gas = model.gas
            initialValues.maxFeePerGas = model.maxFeePerGasInWei
            initialValues.maxPriorityFee = model.maxPriorityFeePerGasInWei

            formModel = model

        default:
            if chain.features?.contains("EIP1559") == true {
                formModel = Fee1559FormModel(
                    nonce: nil,
                    gas: nil,
                    maxFeePerGasInWei: nil,
                    maxPriorityFeePerGasInWei: nil,
                    nativeCurrency: chain.nativeCurrency!
                )
            } else {
                formModel = FeeLegacyFormModel(
                    nonce: nil,
                    gas: nil,
                    gasPriceInWei: nil,
                    nativeCurrency: chain.nativeCurrency!
                )
            }
        }

        let formVC = FormViewController(model: formModel) { [weak self] in
            // on close - ignore any changes
            self?.dismiss(animated: true)
        }

        formVC.trackingEvent = .reviewExecutionEditFee

        formVC.onSave = { [weak self, weak formModel] in
            // on save - update the parameters that were changed.
            self?.dismiss(animated: true, completion: {
                guard let self = self, let formModel = formModel else { return }

                // collect the saved values

                var savedValues = UserDefinedTransactionParameters()

                switch formModel {
                case let model as FeeLegacyFormModel:
                    savedValues.nonce = model.nonce
                    savedValues.gas = model.gas
                    savedValues.gasPrice = model.gasPriceInWei

                case let model as Fee1559FormModel:
                    savedValues.nonce = model.nonce
                    savedValues.gas = model.gas
                    savedValues.maxFeePerGas = model.maxFeePerGasInWei
                    savedValues.maxPriorityFee = model.maxPriorityFeePerGasInWei

                default:
                    break
                }

                // compare the initial snapshot and saved snapshot
                // memberwise and remember only those values that changed.

                var changedFieldTrackingIds: [String] = []

                if savedValues.nonce != initialValues.nonce {
                    self.userParameters.nonce = savedValues.nonce

                    changedFieldTrackingIds.append("nonce")
                }

                if savedValues.gas != initialValues.gas {
                    self.userParameters.gas = savedValues.gas

                    changedFieldTrackingIds.append("gasLimit")
                }

                if savedValues.gasPrice != initialValues.gasPrice {
                    self.userParameters.gasPrice = savedValues.gasPrice

                    changedFieldTrackingIds.append("gasPrice")
                }

                if savedValues.maxFeePerGas != initialValues.maxFeePerGas {
                    self.userParameters.maxFeePerGas = savedValues.maxFeePerGas

                    changedFieldTrackingIds.append("maxFee")
                }

                if savedValues.maxPriorityFee != initialValues.maxPriorityFee {
                    self.userParameters.maxPriorityFee = savedValues.maxPriorityFee

                    changedFieldTrackingIds.append("maxPriorityFee")
                }

                // react to changes

                if savedValues != initialValues {
                    self.error = nil
                    self.updateEthTransactionWithUserValues()
                    self.estimate()

                    let changedFields = changedFieldTrackingIds.joined(separator: ",")
                    Tracker.trackEvent(.reviewExecutionFieldEdited, parameters: ["fields": changedFields])
                }
            })
        }

        formVC.navigationItem.title = "Edit transaction fee"
        let ribbon = RibbonViewController(rootViewController: formVC)
        let nav = UINavigationController(rootViewController: ribbon)
        present(nav, animated: true, completion: nil)

    }

    func updateEthTransactionWithUserValues() {
        // take the values only if they were set by user (not nil)
        switch transaction {
        case var ethTx as Eth.TransactionLegacy:
            ethTx.fee.gas = userParameters.gas ?? ethTx.fee.gas
            ethTx.fee.gasPrice = userParameters.gasPrice ?? ethTx.fee.gasPrice
            ethTx.nonce = userParameters.nonce ?? ethTx.nonce

            self.transaction = ethTx
            reloadData()

        case var ethTx as Eth.TransactionEip1559:
            ethTx.fee.gas = userParameters.gas ?? ethTx.fee.gas
            ethTx.fee.maxFeePerGas = userParameters.maxFeePerGas ?? ethTx.fee.maxFeePerGas
            ethTx.fee.maxPriorityFee = userParameters.maxPriorityFee ?? ethTx.fee.maxPriorityFee
            ethTx.nonce = userParameters.nonce ?? ethTx.nonce

            self.transaction = ethTx
            reloadData()

        default:
            break
        }
    }

    // authorize and sign transaction

    // ask pascode

    // sign
}
