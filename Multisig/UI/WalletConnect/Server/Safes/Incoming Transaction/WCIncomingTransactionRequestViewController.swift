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

    @IBAction private func reject(_ sender: Any) {

    }

    convenience init(transaction: Transaction,
                     safe: Safe,
                     topic: String) {
        self.init(safe: safe)
        self.transaction = transaction
        self.session = try! Session.from(WCSession.get(topic: topic)!)
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

        App.shared.clientGatewayService.asyncPreviewTransaction(
                transaction: transaction,
                sender: AddressString(safe.addressValue),
                chainId: safe.chain!.id!
        ) { result in
            switch result {
            case .success(let response):
                // Handle result
                print("---> Response (success): \(response)")

            case .failure(let error):
                // handle failure
                print("---> Response: Failure! \(error)")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.walletConnectIncomingTransaction, parameters: trackingParameters)
    }

    override func createSections() {
        sectionItems = [SectionItem.header(headerCell()),
                        SectionItem.data(dataCell()),
                        SectionItem.transactionType(transactionType()),
                        SectionItem.advanced(parametersCell())]
    }

    override func headerCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(IcommingDappInteractionRequestHeaderTableViewCell.self)
        let chain = safe.chain!

        cell.setDapp(imageURL: session.dAppInfo.peerMeta.icons[0], name: session.dAppInfo.peerMeta.name)
        let (addressName, imageURL) = NamingPolicy.name(for: transaction.to.address,
                                                 info: nil,
                                                 chainId: safe.chain!.id!)
        cell.setToAddress(transaction.to.address, label: addressName, imageUri: imageURL, prefix: chain.shortName)
        cell.setFromAddress(safe.addressValue, label: safe.name, prefix: chain.shortName)
        return cell
    }

    func transactionType() -> UITableViewCell {
        let tableCell = tableView.dequeueCell(BorderedInnerTableCell.self)

        tableCell.selectionStyle = .none
        tableCell.verticalSpacing = 16

        tableCell.tableView.registerCell(IncommingTransactionRequestTypeTableViewCell.self)

        let cell = tableCell.tableView.dequeueCell(IncommingTransactionRequestTypeTableViewCell.self)

        cell.set(imageName: "", name: "Contract interaction", description: "swapExactETHForTokens")
        tableCell.setCells([cell])
        tableCell.onCellTap = { [unowned self] _ in

        }

        return tableCell
    }
//    override func headerCell() -> UITableViewCell {
//        let cell = tableView.dequeueCell(DetailTransferInfoCell.self)
//        let chain = safe.chain!
//
//        let coin = chain.nativeCurrency!
//        let decimalAmount = BigDecimal(
//            Int256(transaction.value.value) * -1,
//            Int(coin.decimals)
//        )
//        let amount = TokenFormatter().string(
//            from: decimalAmount,
//            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
//            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ","
//        )
//        let tokenText = "\(amount) \(coin.symbol!)"
//        let tokenDetail = amount == "0" ? "\(transaction.data?.data.count ?? 0) Bytes" : nil
//        let (addressName, _) = NamingPolicy.name(for: transaction.to.address,
//                                                    info: nil,
//                                                    chainId: safe.chain!.id!)
//
//        cell.setToken(text: tokenText, style: .secondary)
//        cell.setToken(image: coin.logoUrl)
//        cell.setDetail(tokenDetail)
//
//        cell.setAddress(transaction.to.address,
//                        label: addressName,
//                        imageUri: nil,
//                        browseURL: chain.browserURL(address: transaction.to.address.checksummed),
//                        prefix: chain.shortName)
//        cell.setOutgoing(true)
//        cell.selectionStyle = .none
//
//        return cell
//    }

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

