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
    
    @IBOutlet private weak var rejectButton: UIButton!
    @IBOutlet private weak var submitButton: UIButton!

    var onReject: (() -> Void)?
    var onSubmit: ((_ nonce: UInt256String, _ safeTxHash: HashString) -> Void)?

    private var session: Session!
    private var transaction: Transaction!
    private lazy var trackingParameters: [String: Any] = { ["chain_id": safe.chain!.id!] }()

    convenience init(transaction: Transaction,
                     safe: Safe,
                     topic: String) {
        self.init(safe: safe)
        self.transaction = transaction
        self.session = try! Session.from(WCSession.get(topic: topic)!)
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

        cell.setDapp(imageURL: session.dAppInfo.peerMeta.icons[0], name: session.dAppInfo.peerMeta.name)
        let (addressName, imageURL) = NamingPolicy.name(for: transaction.to.address,
                                                 info: nil,
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

        cell.set(imageName: "", name: "Contract interaction", description: description)
        tableCell.setCells([cell])

        return tableCell
    }

    override func createTransaction() -> Transaction? {
        transaction
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
}

