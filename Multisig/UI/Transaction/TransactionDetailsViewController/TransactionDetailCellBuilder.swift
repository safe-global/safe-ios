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

    private (set) weak var vc: UIViewController!
    private (set) weak var tableView: UITableView!

    // needed for proper safe selection for known addresses functionality. Also used to select the block explorer url.
    private(set) var chain: Chain

    private lazy var dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = .autoupdatingCurrent
        d.dateStyle = .medium
        d.timeStyle = .medium
        return d
    }()
    var result: [UITableViewCell] = []

    init(vc: UIViewController, tableView: UITableView, chain: Chain) {
        self.vc = vc
        self.tableView = tableView
        self.chain = chain

        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerCell(DetailConfirmationCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(DetailAccountAndTextCell.self)
        tableView.registerCell(DetailMultiAccountsCell.self)
        tableView.registerCell(DetailDisclosingCell.self)
        tableView.registerCell(ExternalURLCell.self)
        tableView.registerCell(DetailTransferInfoCell.self)
        tableView.registerCell(DetailRejectionInfoCell.self)
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
        if let factory = creationTx.factory?.value.address {
            address(factory,
                    label: creationTx.factory?.name,
                    title: "Factory used",
                    imageUri: creationTx.factory?.logoUri,
                    browseURL: chain.browserURL(address: factory.checksummed),
                    prefix: chain.shortName)
        } else {
            text("No factory used", title: "Factory used", expandableTitle: nil, copyText: nil)
        }
    }

    func buildMasterCopyUsed(_ creationTx: SCGModels.TxInfo.Creation) {
        if let implementation = creationTx.implementation?.value.address {
            address(
                implementation,
                label: creationTx.implementation?.name ?? "Unknown",
                title: "Base contract used",
                imageUri: creationTx.implementation?.logoUri,
                browseURL: chain.browserURL(address: implementation.checksummed),
                prefix: chain.shortName)
        } else {
            text(
                "Not available",
                title: "Base contract used",
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
        let info = NamingPolicy.name(for: creationTx.creator, chainId: chain.id!)
        let creator = creationTx.creator.value.address
        return address(creator,
                       label: info.name,
                       title: "Creator address",
                       imageUri: info.imageUri,
                       browseURL: chain.browserURL(address: creator.checksummed),
                       prefix: chain.shortName)
    }

    func buildHeader(_ tx: SCGModels.TransactionDetails) {

        switch tx.txInfo {

        case .transfer(let transferTx):
            let isOutgoing = transferTx.direction == .outgoing

            var address: Address
            var label: String?
            var addressLogoUri: URL?
            if isOutgoing {
                address = transferTx.recipient.value.address
                (label, addressLogoUri) = NamingPolicy.name(for: transferTx.recipient, chainId: chain.id!)
            } else {
                address = transferTx.sender.value.address
                (label, addressLogoUri) = NamingPolicy.name(for: transferTx.sender, chainId: chain.id!)
            }

            switch transferTx.transferInfo {

            case .erc20(let erc20Tx):
                buildTransferHeader(
                    address: address,
                    label: label,
                    addressLogoUri: addressLogoUri,
                    isOutgoing: isOutgoing,
                    status: tx.txStatus,
                    value: erc20Tx.value.value,
                    decimals: erc20Tx.decimals,
                    symbol: erc20Tx.tokenSymbol ?? "ERC20",
                    logoUri: erc20Tx.logoUri)

            case .erc721(let erc721Tx):
                buildTransferHeader(
                    address: address,
                    label: label,
                    addressLogoUri: addressLogoUri,
                    isOutgoing: isOutgoing,
                    status: tx.txStatus,
                    value: 1,
                    decimals: 0,
                    symbol: erc721Tx.tokenSymbol ?? "NFT",
                    logoUri: erc721Tx.logoUri,
                    logo: UIImage(named: "ico-nft-placeholder"),
                    detail: erc721Tx.tokenId.description)

            case .nativeCoin(let nativeCoinTx):
                let coin = Chain.nativeCoin!

                buildTransferHeader(
                    address: address,
                    label: label,
                    addressLogoUri: addressLogoUri,
                    isOutgoing: isOutgoing,
                    status: tx.txStatus,
                    value: nativeCoinTx.value.value,
                    decimals: UInt64(coin.decimals),
                    symbol: coin.symbol!,
                    logoUri: coin.logoUrl.map(\.absoluteString))

            case .unknown:
                buildTransferHeader(
                    address: address,
                    label: label,
                    addressLogoUri: addressLogoUri,
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
                let handler: Address = fallbackTx.handler.value.address
                var (label, imageUri) = NamingPolicy.name(for: fallbackTx.handler, chainId: chain.id!)
                if label == nil {
                    label = handler.isZero ? "Not set" : "Unknown"
                }
                address(
                    handler,
                    label: label,
                    title: "Set fallback handler:",
                    imageUri: imageUri,
                    browseURL: chain.browserURL(address: handler.checksummed),
                    prefix: chain.shortName,
                    showDelegateWarning: DelegateWarningCalculator.isUntrusted(txData: tx.txData)
                )

            case .addOwner(let addOwnerTx):
                let (label, imgageUri) = NamingPolicy.name(for: addOwnerTx.owner, chainId: chain.id!)
                addressAndText(
                    addOwnerTx.owner.value.address,
                    label: label,
                    imageUri: imgageUri,
                    addressTitle: "Add owner:",
                    text: "\(addOwnerTx.threshold)",
                    textTitle: "Change required confirmations:",
                    browseURL: chain.browserURL(address: addOwnerTx.owner.value.address.checksummed),
                    prefix: chain.shortName)

            case .removeOwner(let removeOwnerTx):
                let (label, imageUri) = NamingPolicy.name(for: removeOwnerTx.owner, chainId: chain.id!)
                addressAndText(
                    removeOwnerTx.owner.value.address,
                    label: label,
                    imageUri: imageUri,
                    addressTitle: "Remove owner:",
                    text: "\(removeOwnerTx.threshold)",
                    textTitle: "Change required confirmations:",
                    browseURL: chain.browserURL(address: removeOwnerTx.owner.value.address.checksummed),
                    prefix: chain.shortName)

            case .swapOwner(let swapOwnerTx):
                let (oldOwnerLabel, oldOwnerImgageUri) = NamingPolicy.name(for: swapOwnerTx.oldOwner, chainId: chain.id!)
                let (newOwnerLabel, newOwnerImgageUri) = NamingPolicy.name(for: swapOwnerTx.newOwner, chainId: chain.id!)
                addresses(
                    [(address: swapOwnerTx.oldOwner.value.address,
                      label: oldOwnerLabel,
                      imageUri: oldOwnerImgageUri,
                      title: "Remove owner:",
                      browseURL: chain.browserURL(address: swapOwnerTx.oldOwner.value.address.checksummed),
                      prefix: chain.shortName),
                     (address: swapOwnerTx.newOwner.value.address,
                      label: newOwnerLabel,
                      imageUri: newOwnerImgageUri,
                      title: "Add owner:",
                      browseURL: chain.browserURL(address: swapOwnerTx.newOwner.value.address.checksummed),
                      prefix: chain.shortName)
                    ])

            case .changeThreshold(let thresholdTx):
                text(
                    "\(thresholdTx.threshold)",
                    title: "Change required confirmations:",
                    expandableTitle: nil,
                    copyText: nil)

            case .changeImplementation(let implementationTx):
                let implementation = implementationTx.implementation.value.address
                var (label, imageUri) = NamingPolicy.name(for: implementationTx.implementation, chainId: chain.id!)
                if label == nil {
                    label = implementationTx.implementation.name ?? "Unknown"
                }
                address(implementation,
                        label: label,
                        title: "New mastercopy:",
                        imageUri: imageUri,
                        browseURL: chain.browserURL(address: implementation.checksummed),
                        prefix: chain.shortName,
                        showDelegateWarning: DelegateWarningCalculator.isUntrusted(txData: tx.txData)
                )

            case .enableModule(let moduleTx):
                let (label, imageUri) = NamingPolicy.name(for: moduleTx.module, chainId: chain.id!)
                let module = moduleTx.module.value.address
                address(module,
                        label: label,
                        title: "Enable module:",
                        imageUri: imageUri,
                        browseURL: chain.browserURL(address: module.checksummed),
                        prefix: chain.shortName,
                        showDelegateWarning: DelegateWarningCalculator.isUntrusted(txData: tx.txData)
                )

            case .disableModule(let moduleTx):
                let (label, imageUri) = NamingPolicy.name(for: moduleTx.module, chainId: chain.id!)
                let module = moduleTx.module.value.address
                address(module,
                        label: label,
                        title: "Disable module:",
                        imageUri: imageUri,
                        browseURL: chain.browserURL(address: module.checksummed),
                        prefix: chain.shortName,
                        showDelegateWarning: DelegateWarningCalculator.isUntrusted(txData: tx.txData)
                )
                
            case .setGuard(let guardTx):
                let (label, imageUri) = NamingPolicy.name(for: guardTx.guard, chainId: chain.id!)
                let guardContract = guardTx.guard.value.address
                address(guardContract,
                        label: label,
                        title: "Set guard:",
                        imageUri: imageUri,
                        browseURL: chain.browserURL(address: guardContract.checksummed),
                        prefix: chain.shortName,
                        showDelegateWarning: DelegateWarningCalculator.isUntrusted(txData: tx.txData)
                )
                
            case .deleteGuard:
                text("Delete Guard", title: "Settings change:", expandableTitle: nil, copyText: nil)

            case .unknown:
                text("Unknown operation", title: "Settings change:", expandableTitle: nil, copyText: nil)
            }

        case .custom(let customTx):
            let (label, addressLogoUri) = NamingPolicy.name(for: customTx.to, chainId: chain.id!)
            var title = "Interact with: "
            let amount = Int256(customTx.value.value)
            if customTx.value != "0"  {
                let nativeCoinDecimals = chain.nativeCurrency!.decimals

                let decimalAmount = BigDecimal(amount, Int(nativeCoinDecimals))
                let amount = TokenFormatter().string(
                        from: decimalAmount,
                        decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                        thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                        forcePlusSign: false
                )
                
                if let currencySymbol = chain.nativeCurrency?.symbol {
                    title = "Interact with (Send \(amount) \(currencySymbol) to): "
                } else {
                    title = "Interact with (Send \(amount) to): "
                }
            }

            address(customTx.to.value.address,
                label: label,
                title: title,
                imageUri: addressLogoUri,
                browseURL: chain.browserURL(address: customTx.to.value.address.checksummed),
                prefix: chain.shortName,
                showDelegateWarning: DelegateWarningCalculator.isUntrusted(txData: tx.txData)
            )
            buildActions(tx)
            buildHexData(tx)
        case .rejection(_):
            if case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigInfo)? = tx.detailedExecutionInfo {
                rejectionHeader(nonce: multisigInfo.nonce.value, isQueued: tx.txStatus.isInQueue)
            } else {
                rejectionHeader(nonce: nil, isQueued: tx.txStatus.isInQueue)
            }
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
        label: String?,
        addressLogoUri: URL?,
        isOutgoing: Bool,
        status txStatus: SCGModels.TxStatus,
        value: UInt256?,
        decimals: UInt64?,
        symbol: String,
        logoUri: String?,
        logo: UIImage? = UIImage(named: "ico-token-placeholder"),
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


        let style: GNOTextStyle = isOutgoing ? .headline : .headlineBaseSuccess

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
            addressLogoUri: addressLogoUri,
            isOutgoing: isOutgoing)
    }


    func buildActions(_ tx: SCGModels.TransactionDetails) {
        if let dataDecoded = tx.txData?.dataDecoded {
            let addressInfoIndex = tx.txData?.addressInfoIndex

            if dataDecoded.method == "multiSend",
               let param = dataDecoded.parameters?.first,
               param.type == "bytes",
               case let SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(multiSendTxs)? = param.valueDecoded {

                disclosure(text: "Multisend (\(multiSendTxs.count) actions)") { [weak self] in
                    guard let `self` = self else { return }
                    let root = MultiSendListTableViewController(transactions: multiSendTxs,
                                                                addressInfoIndex: addressInfoIndex,
                                                                chain: self.chain)
                    let vc = RibbonViewController(rootViewController: root)
                    self.vc.show(vc, sender: self)
                }
            } else {
                disclosure(text: "Action (\(dataDecoded.method))") { [weak self] in
                    guard let `self` = self else { return }
                    let root = ActionDetailViewController(decoded: dataDecoded,
                                                          addressInfoIndex: addressInfoIndex,
                                                          chain: self.chain,
                                                          data: tx.txData?.hexData)
                    let vc = RibbonViewController(rootViewController: root)
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
                let tokenAddress = erc721Tx.tokenAddress.address
                address(tokenAddress,
                        label: "Asset Contract",
                        title: nil,
                        browseURL: chain.browserURL(address: tokenAddress.checksummed),
                        prefix: chain.shortName)
            default:
                break
            }
        default:
            break
        }
    }

    func buildStatus(_ tx: SCGModels.TransactionDetails) {
        var type = ""
        var tag: String = ""
        var icon: UIImage?
        var imageURL: URL?

        switch tx.txInfo {
        case .transfer(let transferTx):
            let isOutgoing = transferTx.direction == .outgoing
            type = isOutgoing ? "Outgoing transfer" : "Incoming transfer"
            icon = isOutgoing ? UIImage(named: "ico-outgoing-tx") : UIImage(named: "ico-incomming-tx")?.withTintColor(.success)
        case .settingsChange(_):
            type = "Modify settings"
            icon = UIImage(named: "ico-settings-tx")
        case .custom(_):
            if let safeAppInfo = tx.safeAppInfo {
                type = safeAppInfo.name
                imageURL = URL(string: safeAppInfo.logoUri)
                tag = "App"
                icon = UIImage(named: "ico-custom-tx")
            } else {
                type = "Contract interaction"
                icon = UIImage(named: "ico-custom-tx")
            }
        case .rejection(_):
            type = "On-chain rejection"
            icon = UIImage(named: "ico-rejection-tx")
        case .creation(_):
            type = "Safe Account created"
            icon = UIImage(named: "ico-settings-tx")
        case .unknown:
            type = "Unknown operation"
            icon = UIImage(named: "ico-custom-tx")
        }

        status(tx.txStatus, type: type, icon: icon, iconURL: imageURL, address: nil, tag: tag)
    }

    func buildMultisigInfo(_ tx: SCGModels.TransactionDetails) {
        guard case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigInfo)? =
                tx.detailedExecutionInfo else {
            return
        }

        confirmation(multisigInfo.confirmations.map { $0.signer.value.address },
                     required: Int(multisigInfo.confirmationsRequired),
                     status: tx.txStatus,
                     executor: multisigInfo.executor?.value.address, isRejectionTx: tx.txInfo.isRejection)

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
            disclosure(text: "Advanced") { [weak self] in
                guard let `self` = self else { return }
                let vc = AdvancedTransactionDetailsViewController(tx, chain: self.chain)
                let ribbonVC = RibbonViewController(rootViewController: vc)
                self.vc.show(ribbonVC, sender: self)
            }
            break
        }
    }

    func buildOpenInExplorer(hash: DataString?) {
        guard
            let txHash = hash?.description
        else { return }
        let url = chain.browserURL(txHash: txHash)
        externalURL(text: "View on block explorer", url: url)
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

    func confirmation(_ confirmations: [Address], required: Int, status: SCGModels.TxStatus, executor: Address?, isRejectionTx: Bool) {
        let cell = newCell(DetailConfirmationCell.self)
        cell.setConfirmations(confirmations,
                              chain: chain,
                              required: required,
                              status: status,
                              executor: executor,
                              isRejectionTx: isRejectionTx)
        result.append(cell)
    }

    func status(_ status: SCGModels.TxStatus, type: String, icon: UIImage?, iconURL: URL? = nil, address: AddressString? = nil, tag: String = "") {
        let cell = newCell(DetailStatusCell.self)
        cell.setTitle(type)

        cell.setStatus(status)
        cell.set(tag: tag)
        if let imageURL = iconURL, let placeholderAddress = address {
            cell.set(contractImageUrl: imageURL, contractAddress: placeholderAddress)
        } else if let imageURL = iconURL {
            cell.set(imageUrl: imageURL, placeholder: icon)
        } else if let image = icon {
            cell.setIcon(image)
        } else if let placeholderAddress = address {
            cell.set(contractAddress: placeholderAddress)
        }

        result.append(cell)
    }

    func transfer(token: String,
                  style: GNOTextStyle,
                  icon: UIImage?,
                  iconURL: URL?,
                  alpha: CGFloat,
                  detail: String?,
                  address: Address,
                  label: String?, // todo: rename
                  addressLogoUri: URL?,
                  isOutgoing: Bool) {
        let cell = newCell(DetailTransferInfoCell.self)
        cell.setToken(text: token, style: style)
        cell.setToken(image: iconURL, placeholder: icon)
        cell.setToken(alpha: alpha)
        cell.setDetail(detail)
        cell.setAddress(address,
                        label: label,
                        imageUri: addressLogoUri,
                        browseURL: chain.browserURL(address: address.checksummed),
                        prefix: chain.shortName)
        cell.setOutgoing(isOutgoing)
        result.append(cell)
    }

    func rejectionHeader(nonce: UInt256?, isQueued: Bool) {
        let cell = newCell(DetailRejectionInfoCell.self)
        cell.setNonce(nonce, showHelpLink: isQueued)
        result.append(cell)
    }

    func address(_ address: Address,
                 label: String?,
                 title: String?,
                 imageUri: URL? = nil,
                 browseURL: URL? = nil,
                 prefix: String? = nil,
                 showDelegateWarning: Bool = false) {

        let cell = newCell(DetailAccountCell.self)
        cell.setAccount(address: address,
                        label: label,
                        title: title,
                        imageUri: imageUri,
                        browseURL: browseURL,
                        prefix: prefix,
                        showDelegateWarning: showDelegateWarning)
        result.append(cell)
    }

    func addressAndText(_ address: Address,
                        label: String?,
                        imageUri: URL?,
                        addressTitle: String,
                        text: String,
                        textTitle: String,
                        browseURL: URL?,
                        prefix: String?) {
        let cell = newCell(DetailAccountAndTextCell.self)
        cell.setText(title: textTitle, details: text)
        cell.setAccount(address: address,
                        label: label,
                        title: addressTitle,
                        imageUri: imageUri,
                        browseURL: browseURL,
                        prefix: prefix)
        result.append(cell)
    }

    func addresses(_ accounts: [(address: Address,
                                 label: String?,
                                 imageUri: URL?,
                                 title: String?,
                                 browseURL: URL?,
                                 prefix: String?)]) {
        let cell = newCell(DetailMultiAccountsCell.self)
        cell.setAccounts(accounts: accounts)
        result.append(cell)
    }

    func newCell<T: UITableViewCell>(_ cls: T.Type, reuseId: String? = nil) -> T {
        tableView.dequeueCell(cls, reuseID: reuseId)
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

extension SCGModels.TxInfo {
    var isRejection: Bool {
        if case SCGModels.TxInfo.rejection(_) = self {
            return true
        }

        return false
    }
}
