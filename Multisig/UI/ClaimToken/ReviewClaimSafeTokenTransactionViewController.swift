//
//  ReviewClaimSafeTokenTransactionViewController.swift
//  Multisig
//
//  Created by Mouaz on 8/3/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftCryptoTokenFormatter

class ReviewClaimSafeTokenTransactionViewController: ReviewSafeTransactionViewController {
    private var stepLabel: UILabel!
    
    var stepNumber: Int = 4
    var maxSteps: Int = 4

    var onSuccess: (() -> ())?

    private var guardian: Guardian!
    private var amount: String!
    convenience init(safe: Safe, guardian: Guardian, amount: String) {
        self.init(safe: safe)
        self.amount = amount
        self.guardian = guardian
        shouldLoadTransactionPreview = true
    }

    override func viewDidLoad() {
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

        confirmButtonView.onAction = {
            NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
            self.onSuccess?()
        }
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
        SafeTransactionController.shared.claimTokenTransaction(safe: safe, safeTxGas: safeTxGas, nonce: nonce)
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
           case var SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(multiSendTxs)? = param.valueDecoded {
            description = "Multisend (\(multiSendTxs.count) actions)"
            tableCell.onCellTap = { [unowned self] _ in
                multiSendTxs[1].dataDecoded = SCGModels.DataDecoded(method: "redeem")
                multiSendTxs[2].dataDecoded = SCGModels.DataDecoded(method: "claimTokensViaModule")
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

    private var currentDataTask: URLSessionTask?

    override func loadData() {
        guard
            let tx = createTransaction(),
            let chainId = tx.chainId,
            let safeAddress = tx.safe?.address
        else { return }

        startLoading()
        currentDataTask?.cancel()

        self.minimalNonce = UInt256String(safe.nonce ?? 0)
        self.nonce = UInt256String(safe.nonce ?? 0)

        self.currentDataTask = App.shared.clientGatewayService.asyncPreviewTransaction(
            transaction: tx,
            sender: AddressString(self.safe.addressValue),
            chainId: self.safe.chain!.id!
        ) { result in
            switch result {
            case .success(let response):
                self.transactionPreview = response
                self.onSuccess()
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    if (error as NSError).code == URLError.cancelled.rawValue &&
                        (error as NSError).domain == NSURLErrorDomain {
                        return
                    }
                    self.showError(GSError.error(description: "Failed to create transaction", error: error))
                }
            }
        }
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
