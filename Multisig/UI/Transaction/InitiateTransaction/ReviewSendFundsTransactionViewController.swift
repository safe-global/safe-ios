//
//  ReviewSendFundsTransactionViewController.swift
//  Multisig
//
//  Created by Moaaz on 12/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Version
import SwiftCryptoTokenFormatter

fileprivate protocol SectionItem {}

class ReviewSendFundsTransactionViewController: ReviewSafeTransactionViewController {
    var amount: BigDecimal!
    var formattedAmount: String {
        TokenFormatter().string(from: amount, shortFormat: false)
    }
    var recipient: Address!
    var tokenBalance: TokenBalance!
    
    convenience init(safe: Safe, recipient: Address, tokenBalance: TokenBalance, amount: BigDecimal) {
        self.init(safe: safe)
        self.recipient = recipient
        self.amount = amount
        self.tokenBalance = tokenBalance
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(amount != nil)
        assert(safe != nil)
        assert(tokenBalance != nil)

        tableView.registerCell(ReviewSendFundsTransactionHeaderTableViewCell.self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.assetsTransferReview)
    }

    override func createTransaction() -> Transaction? {
        Transaction(safe: safe,
                    toAddress: recipient,
                    tokenAddress: Address(stringLiteral: tokenBalance.address),
                    amount: UInt256String(amount.value),
                    safeTxGas: safeTxGas,
                    nonce: nonce)
    }

    override func headerCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ReviewSendFundsTransactionHeaderTableViewCell.self)
        let prefix = safe.chain!.shortName
        cell.setFromAddress(safe.addressValue, label: safe.name, prefix: prefix)
        let (name, imageURL) = NamingPolicy.name(for: recipient, info: nil, chainId: safe.chain!.id!)
        cell.setToAddress(recipient, label: name, imageUri: imageURL, prefix: prefix)
        cell.setToken(amount: formattedAmount,
                      symbol: tokenBalance.symbol,
                      fiatBalance:  "",
                      image: tokenBalance.imageURL)

        return cell
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {
        let token = tokenBalance.symbol

        let title = "Your transaction is queued!"
        let body = "Your request to send \(formattedAmount) \(token) is submitted and needs to be confirmed by other owners."

        let successVC = SuccessViewController(
            titleText: title,
            bodyText: body,
            primaryAction: "View details",
            secondaryAction: "Done",
            trackingEvent: .assetsTransferSuccess)
        successVC.onDone = { [weak self] isPrimaryAction in
            guard let self = self else { return }
            self.dismiss(animated: true) {
                NotificationCenter.default.post(
                    name: .initiateTxNotificationReceived,
                    object: self,
                    userInfo: isPrimaryAction ? ["transactionDetails": transaction] : [:])
            }
        }

        show(successVC, sender: self)
    }
}
