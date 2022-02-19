//
// Created by Dmitry Bespalov on 18.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import Ethereum

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

    convenience init() {
        self.init(namedClass: WebConnectionContainerViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Execute Transaction Request"

        let chain = controller.chain(for: request)!

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
        guard let keyInfo = try? KeyInfo.firstKey(address: connection.accounts.first!),
        let chain = controller.chain(for: request) else { return }
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

                self.transaction.update(gas: gas, transactionCount: txCount, baseFee: gasPrice)
                self.fee = self.transaction.totalFee.big()
            } catch {
                LogService.shared.error("Error estimating transaction: \(error)")
                self.error = error
            }
            self.reloadData()
        }
    }

    // modifying estimation - copy from the review execution (form)

    // authorize and sign transaction

    // ask pascode

    // sign
}
