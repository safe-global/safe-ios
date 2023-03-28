//
//  ReviewExecutionCellBuilder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import SwiftCryptoTokenFormatter

class ReviewExecutionCellBuilder: TransactionDetailCellBuilder {

    var onTapPaymentMethod: () -> Void = {}
    var onTapAccount: () -> Void = {}
    var onTapFee: () -> Void = {}
    var onTapAdvanced: () -> Void = {}

    private var safe: Safe!

    init(vc: UIViewController, tableView: UITableView, chain: Chain, safe: Safe) {
        super.init(vc: vc, tableView: tableView, chain: chain)
        self.safe = safe

        tableView.registerCell(BorderedInnerTableCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Spacer")
    }

    func build(_ model: ExecutionReviewUIModel) -> [UITableViewCell] {
        result = []
        // nothing to do for creation transaction
        if case SCGModels.TxInfo.creation(_) = model.transaction.txInfo {
            return result
        }
        buildHeader(model.transaction)
        buildAssetContract(model.transaction)
        buildSpacing()
        buildExecutionOptions(model.executionOptions)
        buildErrors(model.errorMessage)
        return result
    }

    func buildSpacing() {
        let cell = newCell(UITableViewCell.self, reuseId: "Spacer")
        cell.contentView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        result.append(cell)
    }

    func buildExecutionOptions(_ model: ExecutionOptionsUIModel) {

        dump(model, name: "ExecutionOptionsUIModel: ")

        let paymentGroupCell = newCell(BorderedInnerTableCell.self)

        paymentGroupCell.tableView.registerCell(DisclosureWithContentCell.self)
        paymentGroupCell.tableView.registerCell(SecondaryDetailDisclosureCell.self)
        paymentGroupCell.tableView.registerCell(PaymentMethodCell.self)

        let estimatedFeeCell = buildEstimatedGasFee(model.feeState, tableView: paymentGroupCell.tableView)

        if case let .filled(relayerInfo) = model.relayerState,
           relayerInfo.remainingRelays > ReviewExecutionViewController.MIN_RELAY_TXS_LEFT {
            let paymentMethod = buildRelayerPayment(model, tableView: paymentGroupCell.tableView)
            paymentGroupCell.setCells([estimatedFeeCell, paymentMethod])
        } else {
            let accountPayment = buildAccountPayment(tableView: paymentGroupCell.tableView)
            let executeWith = buildExecutedWithAccount(model.accountState, tableView: paymentGroupCell.tableView)
            paymentGroupCell.setCells([estimatedFeeCell, accountPayment, executeWith])
        }

        // handle cell taps
        let (feeIndex, paymentIndex, executeWithIndex) = (0, 1, 2)
        paymentGroupCell.onCellTap = { [weak self] index in
            guard let self = self else { return }
            switch index {
            case feeIndex:
                self.onTapFee()
            case paymentIndex:
                self.onTapPaymentMethod()
            case executeWithIndex:
                self.onTapAccount()
            default:
                assertionFailure("Tapped cell at index out of bounds: \(index)")
            }
        }

        result.append(paymentGroupCell)

        buildSpacing()

        let advancedParamCell = newCell(BorderedInnerTableCell.self)
        advancedParamCell.tableView.registerCell(SecondaryDetailDisclosureCell.self)

        let advancedCell = buildAdvancedParameters(tableView: advancedParamCell.tableView)

        advancedParamCell.setCells([advancedCell])

        // handle cell taps
        let (advancedIndex) = (0)
        advancedParamCell.onCellTap = { [weak self] index in
            guard let self = self else { return }
            switch index {
            case advancedIndex:
                self.onTapAdvanced()
            default:
                assertionFailure("Tapped cell at index out of bounds: \(index)")
            }
        }

        result.append(advancedParamCell)
    }

    func buildRelayerPayment(_ model: ExecutionOptionsUIModel, tableView: UITableView) -> UITableViewCell{
        let cell = tableView.dequeueCell(PaymentMethodCell.self)
        if case let .filled(relayerInfo) = model.relayerState {
            cell.setRelaying(relayerInfo.remainingRelays, ReviewExecutionViewController.MAX_RELAY_TXS)
        }
        cell.setBackgroundColor(.backgroundPrimary)
        return cell
    }

    func buildAccountPayment(tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(SecondaryDetailDisclosureCell.self)
        cell.setText("With an owner key")
        cell.setBackgroundColor(.backgroundPrimary)
        return cell
    }

    func buildExecutedWithAccount(_ model: ExecuteWithAccountCellState, tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Select key")
        cell.setBackgroundColor(.backgroundPrimary)
        switch model {
        case .none:
            //TODO: throw
            break
        case .loading:
            let content = loadingView()
            cell.setContent(content)
            
        case .empty:
            let content = textView("Not selected")
            cell.setContent(content)

        case .filled(let accountModel):
            let content = MiniAccountAndBalancePiece()
            content.setModel(accountModel)
            cell.setContent(content)
        }
        return cell
    }

    func buildEstimatedGasFee(_ model: EstimatedFeeCellState, tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Estimated gas fee")
        cell.setBackgroundColor(.backgroundSecondary)

        switch model {
        case .loading:
            let content = loadingView()
            cell.setContent(content)

        case .empty:
            let content = textView("Not set")
            cell.setContent(content)

        case .loaded(let feeModel):
            let amountPiece = AmountAndValuePiece()
            amountPiece.setAmount(feeModel.tokenAmount)
            amountPiece.setFiatAmount(feeModel.fiatAmount)
            cell.setContent(amountPiece)
        }

        return cell
    }

    func textView(_ text: String?) -> UIView {
        let label = UILabel()
        label.textAlignment = .right
        label.setStyle(.body)
        label.text = text
        return label
    }

    func loadingView() -> UIView {
        let skeleton = UILabel()
        skeleton.textAlignment = .right
        skeleton.isSkeletonable = true
        skeleton.skeletonTextLineHeight = .fixed(25)
        skeleton.showSkeleton(delay: 0.2)
        return skeleton
    }

    func buildAdvancedParameters(tableView: UITableView) -> UITableViewCell {
        let advancedCell = tableView.dequeueCell(SecondaryDetailDisclosureCell.self)
        advancedCell.setText("Advanced parameters")
        advancedCell.setBackgroundColor(.backgroundSecondary)
        return advancedCell
    }

    func buildErrors(_ errorText: String?) {
        guard var errorText = errorText else {
            return
        }
        let cell = newCell(DetailExpandableTextCell.self)

        errorText = "!⃤ " + errorText

        // restrict to 1 tweet length
        let errorPreview = errorText.count <= 144 ? nil : (String(errorText.prefix(144)) + "…")
        cell.tableView = tableView
        cell.titleStyle = .calloutMediumError
        cell.expandableTitleStyle = (collapsed: .calloutError, expanded: .calloutError)
        cell.contentStyle = (collapsed: .bodyError, expanded: .body)
        cell.setTitle(nil)
        cell.setText(errorText)
        cell.setCopyText(errorText)
        cell.setExpandableTitle(errorPreview)

        result.append(cell)
    }

    // MARK: New Transfer Header

    override func buildHeader(_ tx: SCGModels.TransactionDetails) {
        // multi-level enums
        guard case SCGModels.TxInfo.transfer(let transferTx) = tx.txInfo else {
            super.buildHeader(tx)
            return
        }

        // amount
        let amountModel = tokenAmount(from: transferTx.transferInfo)
        buildAmount(amountModel: amountModel)

        // from
        let (senderLabel, senderLogo) = NamingPolicy.name(for: transferTx.sender, chainId: chain.id!)
        let senderUrl = chain.browserURL(address: transferTx.sender.value.address.checksummed)

        // to
        let (recipientLabel, recipientLogo) = NamingPolicy.name(for: transferTx.recipient, chainId: chain.id!)
        let recipientUrl = chain.browserURL(address: transferTx.recipient.value.address.checksummed)

        self.addresses([
            (address: transferTx.sender.value.address, label: senderLabel,
             imageUri: senderLogo, title: "From", browseURL: senderUrl, prefix: chain.shortName),

            (address: transferTx.recipient.value.address, label: recipientLabel,
             imageUri: recipientLogo, title: "To", browseURL: recipientUrl, prefix: chain.shortName)
        ])
    }

    func buildAmount(amountModel: TokenAmountUIModel) {
        let cell = newCell(DetailMultiAccountsCell.self)
        let tokenView = TokenInfoView()
        tokenView.setTitle("Amount")
        tokenView.setImage(amountModel.tokenLogoURL, placeholder: amountModel.placeholder)
        tokenView.setText(amountModel.formattedAmount)
        tokenView.setDetail(amountModel.formattedFiatValue, style: .caption1.weight(.medium))
        cell.setViews([tokenView])
        result.append(cell)
    }

    func tokenAmount(from transferInfo: SCGModels.TxInfo.Transfer.TransferInfo) -> TokenAmountUIModel {
        var result = TokenAmountUIModel()

        switch transferInfo {
        case .erc20(let erc20):
            result.value = erc20.value.value
            result.decimals = erc20.decimals
            result.symbol = erc20.tokenSymbol ?? "ERC20"
            result.tokenLogoUri = erc20.logoUri

        case .nativeCoin(let native):
            let coin = Chain.nativeCoin!
            result.value = native.value.value
            result.decimals = UInt64(coin.decimals)
            result.symbol = coin.symbol!
            result.tokenLogoUri = coin.logoUrl?.absoluteString

        case .erc721(let erc721):
            result.value = 1
            result.decimals = 0
            result.symbol = erc721.tokenSymbol ?? "NFT"
            result.tokenLogoUri = erc721.logoUri
            result.placeholder = UIImage(named: "ico-nft-placeholder")
            result.detail = erc721.tokenId.description

        case .unknown:
            break
        }
        return result
    }
}

struct TokenAmountUIModel {
    var value: UInt256?
    var symbol: String = ""
    var decimals: UInt64?
    var detail: String?
    var tokenLogoUri: String?
    var placeholder = UIImage(named: "ico-token-placeholder")

    var formattedAmount: String {
        let tokenAmountText: String
        if let value = value {
            let decimalAmount = BigDecimal(Int256(value),
                                           decimals.flatMap { Int($0) } ?? 0)

            let amount = TokenFormatter().string(
                from: decimalAmount,
                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                forcePlusSign: false
            )

            tokenAmountText = "\(amount) \(symbol)"
        } else {
            tokenAmountText = "Unknown token"
        }
        return tokenAmountText
    }

    var formattedFiatValue: String {
        detail ?? ""
    }

    var tokenLogoURL: URL? {
        tokenLogoUri.flatMap { URL(string: $0) }
    }
}

struct ExecutionReviewUIModel {
    var transaction: SCGModels.TransactionDetails
    var executionOptions: ExecutionOptionsUIModel
    var errorMessage: String?
}

struct ExecutionOptionsUIModel {
    var relayerState: ExecuteWithRelayerCellState = .none
    var accountState: ExecuteWithAccountCellState = .none
    var feeState: EstimatedFeeCellState = .loading
}

enum ExecuteWithAccountCellState {
    case none
    case loading
    case empty
    case filled(MiniAccountInfoUIModel)
}

enum ExecuteWithRelayerCellState {
    case none
    case loading
    case filled(RelayerInfoUIModel)
}

struct RelayerInfoUIModel {
    var remainingRelays: Int
}

struct MiniAccountInfoUIModel {
    var prefix: String?
    var address: Address
    var label: String?
    var imageUri: URL?
    var badge: String?
    var balance: String?
}

enum EstimatedFeeCellState {
    case loading
    case empty
    case loaded(EstimatedFeeUIModel)
}

struct EstimatedFeeUIModel {
    var tokenAmount: String
    var fiatAmount: String?
}
