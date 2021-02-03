//
//  TransactionDetailCellBuilder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import SwiftCryptoTokenFormatter
import SwiftUI

class TransactionDetailCellBuilder {

    private weak var vc: UIViewController!
    private weak var tableView: UITableView!
    private lazy var dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = .autoupdatingCurrent
        d.dateStyle = .medium
        d.timeStyle = .medium
        return d
    }()
    var result: [UITableViewCell] = []

    init(vc: UIViewController, tableView: UITableView) {
        self.vc = vc
        self.tableView = tableView
        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerCell(DetailConfirmationCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(DetailAccountAndTextCell.self)
        tableView.registerCell(DetailMultiAccountsCell.self)
        tableView.registerCell(DetailDisclosingCell.self)
        tableView.registerCell(ExternalURLCell.self)
        tableView.registerCell(DetailTransferInfoCell.self)
        tableView.registerCell(DetailStatusCell.self)
    }

    func build(_ tx: SCGModels.TransactionDetails) -> [UITableViewCell] {
        result = []
        buildTransaction(tx)
        return result
    }

    func buildTransaction(_ tx: SCGModels.TransactionDetails) {
        let isCreationTx = buildCreationTx(tx)
        if !isCreationTx {
            buildHeader(tx)
            buildAssetContract(tx)
            buildStatus(tx)
            buildMultisigInfo(tx)
            buildExecutedDate(tx)
            buildAdvanced(tx)
            buildOpenInExplorer(hash: tx.txHash)
        }
    }

    func buildCreationTx(_ tx: SCGModels.TransactionDetails) -> Bool {
        guard case let SCGModels.TxInfo.creation(creationTx) = tx.txInfo else {
            return false
        }
        buildStatus(tx)
        buildTransactionHash(creationTx)
        buildCreatorAddress(creationTx)
        buildMasterCopyUsed(creationTx)
        buildFactoryUsed(creationTx)
        buildCreatedDate(tx.executedAt)
        buildOpenInExplorer(hash: creationTx.transactionHash)
        return true
    }

    func buildFactoryUsed(_ creationTx: SCGModels.TxInfo.Creation) {
        if let factory = creationTx.factory?.address {
            address(factory, label: nil, title: "Factory used")
        } else {
            text("No factory used", title: "Factory used", expandableTitle: nil, copyText: nil)
        }
    }

    func buildMasterCopyUsed(_ creationTx: SCGModels.TxInfo.Creation) {
        if let implementation = creationTx.implementation?.address {
            address(
                implementation,
                label: App.shared.gnosisSafe.versionNumber(implementation: implementation) ?? "Unknown",
                title: "Mastercopy used")
        } else {
            text(
                "Not available",
                title: "Mastercopy used",
                expandableTitle: nil,
                copyText: nil)
        }
    }

    func buildTransactionHash(_ creationTx: SCGModels.TxInfo.Creation) {
        text(
            creationTx.transactionHash.description,
            title: "Transaction hash",
            expandableTitle: nil,
            copyText: creationTx.transactionHash.description)
    }

    func buildCreatorAddress(_ creationTx: SCGModels.TxInfo.Creation) {
        address(creationTx.creator.address, label: nil, title: "Creator address")
    }

    func buildHeader(_ tx: SCGModels.TransactionDetails) {

        switch tx.txInfo {

        case .transfer(let transferTx):
            let isOutgoing = transferTx.direction == .outgoing
            let address = isOutgoing ? transferTx.recipient.address : transferTx.sender.address

            switch transferTx.transferInfo {

            case .erc20(let erc20Tx):
                buildTransferHeader(
                    address: address,
                    isOutgoing: isOutgoing,
                    status: tx.txStatus,
                    value: erc20Tx.value.value,
                    decimals: erc20Tx.decimals,
                    symbol: erc20Tx.tokenSymbol ?? "ERC20",
                    logoUri: erc20Tx.logoUri)

            case .erc721(let erc721Tx):
                buildTransferHeader(
                    address: address,
                    isOutgoing: isOutgoing,
                    status: tx.txStatus,
                    value: 1,
                    decimals: 0,
                    symbol: erc721Tx.tokenSymbol ?? "NFT",
                    logoUri: erc721Tx.logoUri,
                    logo: UIImage(named: "ico-nft-placeholder"),
                    detail: erc721Tx.tokenId.description)

            case .ether(let etherTx):
                let eth = App.shared.tokenRegistry.token(address: .ether)!

                buildTransferHeader(
                    address: address,
                    isOutgoing: isOutgoing,
                    status: tx.txStatus,
                    value: etherTx.value.value,
                    decimals: eth.decimals.flatMap { try? UInt64($0) },
                    symbol: eth.symbol,
                    logoUri: nil,
                    logo: #imageLiteral(resourceName: "ico-ether"))

            case .unknown:
                buildTransferHeader(
                    address: address,
                    isOutgoing: isOutgoing,
                    status: tx.txStatus,
                    value: nil,
                    decimals: nil,
                    symbol: "",
                    logoUri: nil)

            }

        case .settingsChange(let settingsTx):

            switch settingsTx.settingsInfo {

            case .setFallbackHandler(let fallbackTx):
                let handler: Address = fallbackTx.handler.address
                address(
                    handler,
                    label: App.shared.gnosisSafe.fallbackHandlerLabel(fallbackHandler: handler),
                    title: "Set fallback handler:")

            case .addOwner(let addOwnerTx):
                addressAndText(
                    addOwnerTx.owner.address,
                    label: nil,
                    addressTitle: "Add owner:",
                    text: "\(addOwnerTx.threshold)",
                    textTitle: "Change required confirmations:")

            case .removeOwner(let removeOwnerTx):
                addressAndText(
                    removeOwnerTx.owner.address,
                    label: nil,
                    addressTitle: "Remove owner:",
                    text: "\(removeOwnerTx.threshold)",
                    textTitle: "Change required confirmations:")

            case .swapOwner(let swapOwnerTx):
                addresses(
                    [(address: swapOwnerTx.oldOwner.address, label: nil, title: "Remove owner:"),
                     (address: swapOwnerTx.newOwner.address, label: nil, title: "Add owner:")
                    ])

            case .changeThreshold(let thresholdTx):
                text(
                    "\(thresholdTx.threshold)",
                    title: "Change required confirmations:",
                    expandableTitle: nil,
                    copyText: nil)

            case .changeImplementation(let implementationTx):
                let implementation = implementationTx.implementation.address
                address(implementation,
                        label: App.shared.gnosisSafe.versionNumber(implementation: implementation) ?? "Unknown",
                        title: "New mastercopy:")

            case .enableModule(let moduleTx):
                address(moduleTx.module.address, label: nil, title: "Enable module:")

            case .disableModule(let moduleTx):
                address(moduleTx.module.address, label: nil, title: "Disable module:")

            case .unknown:
                text("Unknown operation", title: "Settings change:", expandableTitle: nil, copyText: nil)
            }

        case .custom(let customTx):
            let eth = App.shared.tokenRegistry.token(address: .ether)!

            buildTransferHeader(
                address: customTx.to.address,
                isOutgoing: true,
                status: tx.txStatus,
                value: customTx.value.value,
                decimals: eth.decimals.flatMap { try? UInt64($0) },
                symbol: eth.symbol,
                logoUri: nil,
                logo: #imageLiteral(resourceName: "ico-ether"),
                detail: "\(customTx.dataSize.value) bytes")
            buildActions(tx)
            buildHexData(tx)

        case .creation(_):
            // ignore
            fallthrough
        case .unknown:
            // ignore
            break
        }
    }

    // MARK: - Transaction Screen Pieces

    func buildTransferHeader(
        address: Address,
        label: String? = nil,
        isOutgoing: Bool,
        status txStatus: SCGModels.TxStatus,
        value: UInt256?,
        decimals: UInt64?,
        symbol: String,
        logoUri: String?,
        logo: UIImage? = #imageLiteral(resourceName:"ico-token-placeholder"),
        detail: String? = nil
    ) {
        let tokenText: String
        if let value = value {
            let decimalAmount = BigDecimal(Int256(value) * (isOutgoing ? -1 : +1),
                                           decimals.flatMap { Int($0) } ?? 0)

            let amount = TokenFormatter().string(
                from: decimalAmount,
                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                forcePlusSign: true
            )

            tokenText = "\(amount) \(symbol)"
        } else {
            tokenText = "Unknown token"
        }


        let style: GNOTextStyle = isOutgoing ? .secondary : .primaryButton

        let iconURL = logoUri.flatMap { URL(string: $0) }

        let alpha: CGFloat = [SCGModels.TxStatus.cancelled, .failed].contains(txStatus) ? 0.5 : 1

        transfer(
            token: tokenText,
            style: style,
            icon: logo,
            iconURL: iconURL,
            alpha: alpha,
            detail: detail,
            address: address,
            label: label,
            isOutgoing: isOutgoing)
    }


    func buildActions(_ tx: SCGModels.TransactionDetails) {
        if let dataDecoded = tx.txData?.dataDecoded {

            if dataDecoded.method == "multiSend",
               let param = dataDecoded.parameters?.first,
               param.type == "bytes",
               case let SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(multiSendTxs)? = param.valueDecoded {

                disclosure(text: "Multisend (\(multiSendTxs.count) actions)") { [weak self] in
                    guard let `self` = self else { return }
                    let vc = MultiSendListTableViewController(multiSendTxs)
                    self.vc.show(vc, sender: self)
                }
            } else {
                disclosure(text: "Action (\(dataDecoded.method))") { [weak self] in
                    guard let `self` = self else { return }
                    let vc = ActionDetailViewController(decoded: dataDecoded, data: tx.txData?.hexData)
                    self.vc.show(vc, sender: self)
                }
            }
        }
    }

    func buildHexData(_ tx: SCGModels.TransactionDetails) {
        if let data = tx.txData?.hexData {
            text("\(data)", title: "Data", expandableTitle: "\(data.data.count) Bytes", copyText: "\(data)")
        }
    }

    func buildAssetContract(_ tx: SCGModels.TransactionDetails) {
        switch tx.txInfo {
        case .transfer(let transferTx):
            switch transferTx.transferInfo {
            case .erc721(let erc721Tx):
                address(erc721Tx.tokenAddress.address, label: "Asset Contract", title: nil)
            default:
                break
            }
        default:
            break
        }
    }

    func buildStatus(_ tx: SCGModels.TransactionDetails) {
        switch tx.txInfo {
        case .transfer(let transferTx):
            let isOutgoing = transferTx.direction == .outgoing
            let type = isOutgoing ? "Outgoing transfer" : "Incoming transfer"
            let icon = isOutgoing ? #imageLiteral(resourceName: "ico-outgoing-tx") : #imageLiteral(resourceName: "ico-incoming-tx")
            status(tx.txStatus, type: type, icon: icon)
        case .settingsChange(_):
            status(tx.txStatus, type: "Modify settings", icon: #imageLiteral(resourceName: "ico-settings-tx"))
        case .custom(_):
            status(tx.txStatus, type: "Contract interaction", icon: #imageLiteral(resourceName: "ico-custom-tx"))
        case .creation(_):
            status(tx.txStatus, type: "Safe created", icon: #imageLiteral(resourceName: "ico-settings-tx"))
        case .unknown:
            status(tx.txStatus, type: "Unknown operation", icon: #imageLiteral(resourceName: "ico-custom-tx"))
        }
    }

    func buildMultisigInfo(_ tx: SCGModels.TransactionDetails) {
        guard case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigInfo)? =
                tx.detailedExecutionInfo else {
            return
        }
        confirmation(multisigInfo.confirmations.map { $0.signer.address },
                     required: Int(multisigInfo.confirmationsRequired),
                     status: tx.txStatus,
                     executor: multisigInfo.executor?.address)

        buildCreatedDate(multisigInfo.submittedAt)
    }

    func buildCreatedDate(_ date: Date?) {
        guard let date = date else { return }
        text(
            dateFormatter.string(from: date),
            title: "Created:",
            expandableTitle: nil,
            copyText: nil)
    }

    func buildExecutedDate(_ tx: SCGModels.TransactionDetails) {
        guard let executedAt = tx.executedAt else { return }
        text(
            dateFormatter.string(from: executedAt),
            title: "Executed:",
            expandableTitle: nil,
            copyText: nil)
    }

    func buildAdvanced(_ tx: SCGModels.TransactionDetails) {
        switch tx.txInfo {
        case .transfer(let transferTx):
            guard transferTx.direction != .incoming else { return }
            fallthrough
        default:
            let nonce: String?
            let operation: String? = tx.txData?.operation.string
            let hash: String? = tx.txHash?.description
            let safeTxHash: String?

            if case SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(let multisigTx)? =
                tx.detailedExecutionInfo {
                nonce = multisigTx.nonce.description
                safeTxHash = multisigTx.safeTxHash.description
            } else {
                nonce = nil
                safeTxHash = nil
            }

            guard ![nonce, operation, hash, safeTxHash].compactMap({ $0 }).isEmpty else { return }

            disclosure(text: "Advanced") { [weak self] in
                guard let `self` = self else { return }
                let view = AdvancedTransactionDetailsView(
                    nonce: nonce,
                    operation: operation,
                    hash: hash,
                    safeTxHash: safeTxHash)
                let vc = UIHostingController(rootView: view)
                self.vc.show(vc, sender: self)
            }
            break
        }
    }

    func buildOpenInExplorer(hash: DataString?) {
        guard let txHash = hash?.description else { return }
        let url = App.configuration.services.etehreumBlockBrowserURL
            .appendingPathComponent("tx").appendingPathComponent(txHash)
        externalURL(text: "View transaction on Etherscan", url: url)
    }

    // MARK: - Cell Builder

    func disclosure(text: String, action: @escaping () -> Void) {
        let cell = newCell(DetailDisclosingCell.self)
        cell.action = action
        cell.setText(text)
        result.append(cell)
    }

    func externalURL(text: String, url: URL) {
        let cell = newCell(ExternalURLCell.self)
        cell.setText(text, url: url)
        result.append(cell)
    }

    func text(_ text: String, title: String, expandableTitle: String?, copyText: String?) {
        let cell = newCell(DetailExpandableTextCell.self)
        cell.tableView = tableView
        cell.setTitle(title)
        cell.setText(text)
        cell.setCopyText(copyText)
        cell.setExpandableTitle(expandableTitle)
        result.append(cell)
    }


    func confirmation(_ confirmations: [Address], required: Int, status: SCGModels.TxStatus, executor: Address?) {
        let cell = newCell(DetailConfirmationCell.self)
        cell.setConfirmations(confirmations,
                              required: required,
                              status: status,
                              executor: executor)
        result.append(cell)
    }

    func status(_ status: SCGModels.TxStatus, type: String, icon: UIImage) {
        let cell = newCell(DetailStatusCell.self)
        cell.setTitle(type)
        cell.setIcon(icon)
        cell.setStatus(status)
        result.append(cell)
    }
    func transfer(token: String, style: GNOTextStyle, icon: UIImage?, iconURL: URL?, alpha: CGFloat, detail: String?, address: Address, label: String?, isOutgoing: Bool) {
        let cell = newCell(DetailTransferInfoCell.self)
        cell.setAddress(address, label: label)
        cell.setToken(text: token, style: style)
        cell.setToken(image: iconURL, placeholder: icon)
        cell.setToken(alpha: alpha)
        cell.setDetail(detail)
        cell.setAddress(address, label: label)
        cell.setOutgoing(isOutgoing)
        result.append(cell)
    }

    func address(_ address: Address, label: String?, title: String?) {
        let cell = newCell(DetailAccountCell.self)
        cell.setAccount(address: address.checksummed, label: label, title: title)
        result.append(cell)
    }

    func addressAndText(_ address: Address, label: String?, addressTitle: String, text: String, textTitle: String) {
        let cell = newCell(DetailAccountAndTextCell.self)
        cell.setText(title: textTitle, details: text)
        cell.setAccount(address: address, label: label, title: addressTitle)
        result.append(cell)
    }

    func addresses(_ accounts: [(address: Address, label: String?, title: String?)]) {
        let cell = newCell(DetailMultiAccountsCell.self)
        cell.setAccounts(accounts: accounts)
        result.append(cell)
    }


    func newCell<T: UITableViewCell>(_ cls: T.Type) -> T {
        tableView.dequeueCell(cls)
    }
}

extension SCGModels.Operation {
    static let strings: [Self: String] = [
        .call: "call",
        .delegate: "delegateCall"
    ]
    var string: String {
        Self.strings[self]!
    }
}
