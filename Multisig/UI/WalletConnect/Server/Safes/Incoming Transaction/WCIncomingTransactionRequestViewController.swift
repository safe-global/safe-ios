//
//  WCIncomingTransactionRequestViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift
import Kingfisher
import SwiftCryptoTokenFormatter
import Version

fileprivate protocol SectionItem {}

class WCIncomingTransactionRequestViewController: ReviewSafeTransactionViewController {
    var onReject: (() -> Void)?
    var onSubmit: ((_ nonce: UInt256String, _ safeTxHash: HashString) -> Void)?

    private var session: Session!
    private var dAppName: String!
    private var dAppIconURL: URL?
    private var transaction: Transaction!
    private lazy var trackingParameters: [String: Any] = { ["chain_id": safe.chain!.id!] }()

    convenience init(transaction: Transaction,
                     safe: Safe,
                     dAppName: String,
                     dAppIconURL: URL?) {
        self.init(safe: safe)
        self.transaction = transaction
        self.dAppName = dAppName
        self.dAppIconURL = dAppIconURL
        shouldLoadTransactionPreview = true
    }

    // MARK: - ViewController life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = nil

        confirmButtonView.rejectTitle = "Reject"
        confirmButtonView.set(rejectionEnabled: true)
        confirmButtonView.onReject = { [unowned self] in
            onReject?()
            dismiss(animated: true, completion: nil)
        }

        tableView.registerCell(IcommingDappInteractionRequestHeaderTableViewCell.self)
        tableView.registerCell(DetailTransferInfoCell.self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.walletConnectIncomingTransaction, parameters: trackingParameters)
    }

    override func createSections() {
        sectionItems = [SectionItem.header(headerCell()),
                        SectionItem.data(dataCell())]
        if let _ = transactionPreview?.txData?.dataDecoded {
            sectionItems.append(SectionItem.transactionType(transactionType()))
        }
        sectionItems.append(SectionItem.advanced(parametersCell()))

    }

    override func headerCell() -> UITableViewCell {
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

        cell.setDapp(imageURL: dAppIconURL, name: dAppName)
        let (addressName, imageURL) = NamingPolicy.name(for: transaction.to.address,
                                                        info: addressInfo?.addressInfo,
                                                        chainId: safe.chain!.id!)
        cell.setToAddress(transaction.to.address,
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
            name = "Safe Account created"
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

    override func createTransaction() -> Transaction? {
        transaction.update(nonce: nonce, safeTxGas: safeTxGas)
        return transaction
    }

    override func getTrackingEvent() -> TrackingEvent {
        .walletConnectEditParameters
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sectionItems[indexPath.row]
        switch item {
        case SectionItem.transactionType(let cell): return cell
        default: return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        App.shared.snackbar.show(message: "The transaction is submitted and can be confirmed by other owners.")

        guard let multisigInfo = transaction.multisigInfo else { return }
        onSubmit?(multisigInfo.nonce, multisigInfo.safeTxHash)
    }
}

