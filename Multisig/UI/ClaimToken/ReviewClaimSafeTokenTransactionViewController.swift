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
    private var stepLabel: UILabel!
    
    var stepNumber: Int = 4
    var maxSteps: Int = 4

    var amount: Sol.UInt128!
    var claimData: ClaimingAppController.ClaimingData!
    var timestamp: TimeInterval!
    var selectedGuardian: Guardian?
    var selectedCustomAddress: Address?

    var controller: ClaimingAppController!

    var onSuccess: ((SCGModels.TransactionDetails) -> ())?

    convenience init(
        safe: Safe,
        amount: Sol.UInt128,
        claimData: ClaimingAppController.ClaimingData,
        timestamp: TimeInterval,
        guardian: Guardian?,
        customAddress: Address?,
        controller: ClaimingAppController,
        onSuccess: @escaping (SCGModels.TransactionDetails) -> Void
    ) {
        self.init(safe: safe)
        self.amount = amount
        self.claimData = claimData
        self.timestamp = timestamp
        self.selectedGuardian = selectedGuardian
        self.selectedCustomAddress = selectedCustomAddress
        self.controller = controller
        self.onSuccess = onSuccess
    }

    override func viewDidLoad() {
        shouldLoadTransactionPreview = true

        super.viewDidLoad()
        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"
        
        navigationItem.title = "Review transaction"
        confirmButtonView.set(rejectionEnabled: false)

        tableView.registerCell(IcommingDappInteractionRequestHeaderTableViewCell.self)
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

    override func createTransaction() -> Transaction? {
        let delegateAddress = selectedCustomAddress ?? selectedGuardian?.address.address
        let contractDelegate = claimData.delegate.map(Address.init)
        let sameDelegateAsInContract = contractDelegate != nil && contractDelegate == delegateAddress
        let newDelegateAddress: Address? = sameDelegateAsInContract ? nil : delegateAddress
        var result = controller.claimingTransaction(
            safe: self.safe,
            amount: amount,
            delegate: newDelegateAddress,
            data: claimData,
            timestamp: timestamp
        )
        result?.update(nonce: nonce, safeTxGas: safeTxGas)
        return result
    }

    override func headerCell() -> UITableViewCell {
        guard let tx = createTransaction() else { return UITableViewCell() }
        let cell = tableView.dequeueCell(IcommingDappInteractionRequestHeaderTableViewCell.self)
        let chain = safe.chain!
        var addressInfo: SCGModels.AddressInfo?

        switch transactionPreview!.txInfo {
        case .transfer(let transferInfo):
            let isOutgoing = transferInfo.direction == .outgoing
            if isOutgoing {
               addressInfo = transferInfo.recipient
            } else {
                addressInfo = transferInfo.sender
            }
        case .custom(let customInfo):
            addressInfo = customInfo.to
        default:
            addressInfo = transactionPreview?.txData?.to
        }

        let (addressName, imageURL) = NamingPolicy.name(for: tx.to.address,
                                                        info: addressInfo?.addressInfo,
                                                        chainId: safe.chain!.id!)
        cell.setDappInfo(hidden: true)
        cell.setToAddress(tx.to.address,
                          label: addressName,
                          imageUri: imageURL,
                          prefix: chain.shortName,
                          title: "Interact with:")
        cell.setFromAddress(safe.addressValue,
                            label: safe.name,
                            prefix: chain.shortName,
                            title: "Sending from:")
        return cell
    }

    func transactionType() -> UITableViewCell {
        guard let dataDecoded = transactionPreview?.txData?.dataDecoded else { return UITableViewCell() }

        let tableCell = tableView.dequeueCell(BorderedInnerTableCell.self)

        tableCell.selectionStyle = .none
        tableCell.verticalSpacing = 16

        tableCell.tableView.registerCell(IncommingTransactionRequestTypeTableViewCell.self)

        let cell = tableCell.tableView.dequeueCell(IncommingTransactionRequestTypeTableViewCell.self)

        let addressInfoIndex = transactionPreview?.txData?.addressInfoIndex
        var description: String?
        var imageName: String = "ico-custom-tx"
        var name: String = "Contract interaction"

        switch transactionPreview!.txInfo {
        case .transfer(let transferInfo):
            let isOutgoing = transferInfo.direction == .outgoing
            imageName = isOutgoing ? "ico-outgoing-tx" : "ico-incomming-tx"
            name = isOutgoing ? "Send" : "Receive"
        case .settingsChange(let settingsChangeInfo):
            name = settingsChangeInfo.dataDecoded.method
            imageName = "ico-settings-tx"
        case .custom(let _):
            name = "Contract interaction"
            imageName = "ico-custom-tx"
        case .rejection(_):
            name = "On-chain rejection"
            imageName = "ico-rejection-tx"
        case .creation(_):
            imageName = "ico-settings-tx"
            name = "Safe created"
        case .unknown:
            imageName = "ico-custom-tx"
            name = "Unknown operation"
        }

        if dataDecoded.method == "multiSend",
           let param = dataDecoded.parameters?.first,
           param.type == "bytes",
           case let SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(multiSendTxs)? = param.valueDecoded {
            description = "Multisend (\(multiSendTxs.count) actions)"
            tableCell.onCellTap = { [unowned self] _ in
                let root = MultiSendListTableViewController(transactions: multiSendTxs,
                                                            addressInfoIndex: addressInfoIndex,
                                                            chain: safe.chain!)
                let vc = RibbonViewController(rootViewController: root)
                show(vc, sender: self)
            }
        } else {
            description = "Action (\(dataDecoded.method))"
            tableCell.onCellTap = { [unowned self] _ in
                let root = ActionDetailViewController(decoded: dataDecoded,
                                                      addressInfoIndex: addressInfoIndex,
                                                      chain: safe.chain!,
                                                      data: transactionPreview?.txData?.hexData)
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

    // TODO: Fill the tracking event
//    override func getTrackingEvent() -> TrackingEvent {
//
//
//    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sectionItems[indexPath.row]
        switch item {
        case SectionItem.transactionType(let cell): return cell
        default: return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
}
