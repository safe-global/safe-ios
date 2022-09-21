//
//  ReviewClaimSafeTokenTransactionViewController.swift
//  Multisig
//
//  Created by Mouaz on 8/3/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftCryptoTokenFormatter
import Solidity

class ReviewClaimSafeTokenTransactionViewController: ReviewSafeTransactionViewController {
    var amount: Sol.UInt128!
    var claimData: ClaimingAppController.ClaimingData!
    var timestamp: TimeInterval!
    var selectedGuardian: Guardian?
    var selectedCustomAddress: Address?
    var controller: ClaimingAppController!
    var maxAmountSelected: Bool = false
    
    var onSuccess: ((SCGModels.TransactionDetails) -> ())?

    convenience init(
        safe: Safe,
        amount: Sol.UInt128,
        maxAmountSelected: Bool = false,
        claimData: ClaimingAppController.ClaimingData,
        timestamp: TimeInterval,
        guardian: Guardian?,
        customAddress: Address?,
        controller: ClaimingAppController,
        onSuccess: @escaping (SCGModels.TransactionDetails) -> Void
    ) {
        self.init(safe: safe)
        self.amount = amount
        self.maxAmountSelected = maxAmountSelected
        self.claimData = claimData
        self.timestamp = timestamp
        self.selectedGuardian = guardian
        self.selectedCustomAddress = customAddress
        self.controller = controller
        self.onSuccess = onSuccess
    }

    override func viewDidLoad() {
        shouldLoadTransactionPreview = true

        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimReview)

        navigationItem.title = "Review transaction"
        confirmButtonView.set(rejectionEnabled: false)

        tableView.registerCell(ReviewClaimTokensHeaderCell.self)
        tableView.registerCell(DetailTransferInfoCell.self)
    }

    override func createSections() {
        sectionItems = [SectionItem.header(headerCell()),
                        SectionItem.data(dataCell())]
        if let _ = transactionPreview?.txData?.dataDecoded {
            sectionItems.append(SectionItem.transactionType(transactionType()))
        }
        sectionItems.append(SectionItem.advanced(parametersCell()))

    }

    var newDelegateAddress: Address? {
        let delegateAddress = selectedCustomAddress ?? selectedGuardian?.address.address
        let contractDelegate = claimData.delegate.map(Address.init)
        let sameDelegateAsInContract = contractDelegate != nil && contractDelegate == delegateAddress
        let result = sameDelegateAsInContract ? nil : delegateAddress
        return result
    }

    override func createTransaction() -> Transaction? {
        var result = controller.claimingTransaction(
            safe: self.safe,
            amount: maxAmountSelected ? Sol.UInt128.max : amount,
            delegate: newDelegateAddress,
            data: claimData,
            timestamp: timestamp
        )
        result?.update(nonce: nonce, safeTxGas: safeTxGas)
        return result
    }

    override func headerCell() -> UITableViewCell {
        guard
            let tx = createTransaction(),
            let chain = safe.chain,
            let preview = transactionPreview,
            let amount = amount
        else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueCell(ReviewClaimTokensHeaderCell.self)

        // set amount and icon
        let formatter = TokenFormatter()
        let amountDecimal = BigDecimal(Int256(amount.big()), 18)
        let displayAmount = formatter.string(from: amountDecimal, shortFormat: false) + " SAFE"
        cell.setAmount(text: displayAmount, image: UIImage(named: "ico-safe-token-logo-circle"))

        cell.showsDelegate = newDelegateAddress != nil
        cell.setDelegate(guardian: selectedGuardian, address: selectedCustomAddress, chain: chain)

        cell.setFrom(address: safe.addressValue, chain: chain)

        // set to - to contract address
        if case SCGModels.TxInfo.custom(let txInfo) = preview.txInfo {
            cell.setTo(info: txInfo.to, chain: chain)
        } else if let data = preview.txData {
            cell.setTo(info: data.to, chain: chain)
        } else {
            cell.setTo(address: tx.to.address, chain: chain)
        }

        return cell
    }

    func transactionType() -> UITableViewCell {
        guard
            let preview = transactionPreview,
            let txData = preview.txData,
            let dataDecoded = txData.dataDecoded
        else {
            return UITableViewCell()
        }

        let tableCell = tableView.dequeueCell(BorderedInnerTableCell.self)

        tableCell.selectionStyle = .none
        tableCell.verticalSpacing = 16

        tableCell.tableView.registerCell(IncommingTransactionRequestTypeTableViewCell.self)

        let cell = tableCell.tableView.dequeueCell(IncommingTransactionRequestTypeTableViewCell.self)

        let description: String
        let imageName: String = "ico-custom-tx"
        let name: String = "Contract interaction"

        if dataDecoded.method == "multiSend",
           let param = dataDecoded.parameters?.first,
           param.type == "bytes",
           case let SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(multiSendTxs)? = param.valueDecoded {
            description = "Multisend (\(multiSendTxs.count) actions)"
            tableCell.onCellTap = { [unowned self] _ in
                Tracker.trackEvent(.userClaimReviewAct)
                
                let root = MultiSendListTableViewController(transactions: multiSendTxs,
                                                            addressInfoIndex: txData.addressInfoIndex,
                                                            chain: safe.chain!)
                let vc = RibbonViewController(rootViewController: root)
                show(vc, sender: self)
            }
        } else {
            description = "Action (\(dataDecoded.method))"
            tableCell.onCellTap = { [unowned self] _ in
                Tracker.trackEvent(.userClaimReviewAct)

                let root = ActionDetailViewController(decoded: dataDecoded,
                                                      addressInfoIndex: txData.addressInfoIndex,
                                                      chain: safe.chain!,
                                                      data: txData.hexData)
                let vc = RibbonViewController(rootViewController: root)
                show(vc, sender: self)
            }
        }

        cell.set(imageName: imageName, name: name, description: description)
        tableCell.setCells([cell])

        return tableCell
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {
        self.onSuccess?(transaction)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sectionItems[indexPath.row]
        switch item {
        case SectionItem.transactionType(let cell): return cell
        default: return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
}
