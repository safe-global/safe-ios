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
    var executionOptionsCellBuilder: ExecutionOptionsCellBuilder
    var onTapPaymentMethod: () -> Void = {}
    var onTapAccount: () -> Void = {}
    var onTapFee: () -> Void = {}
    var onTapAdvanced: () -> Void = {}
    var userSelectedSigner = false

    private var safe: Safe!

    init(vc: UIViewController, tableView: UITableView, chain: Chain, safe: Safe) {
        executionOptionsCellBuilder = ExecutionOptionsCellBuilder(
            vc: vc,
            tableView: tableView,
            chain: chain
        )
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

        executionOptionsCellBuilder.userSelectedSigner = userSelectedSigner
        executionOptionsCellBuilder.onTapPaymentMethod = onTapPaymentMethod
        executionOptionsCellBuilder.onTapAccount = onTapAccount
        executionOptionsCellBuilder.onTapFee = onTapFee
        executionOptionsCellBuilder.onTapAdvanced = onTapAdvanced
        result.append(contentsOf: executionOptionsCellBuilder.buildExecutionOptions(model.executionOptions))
        buildErrors(model.errorMessage)
        return result
    }

    // TODO can this be moved to TransactionDetailCellBuilder ?
    func buildSpacing() {
        let cell = newCell(UITableViewCell.self, reuseId: "Spacer")
        cell.contentView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        result.append(cell)
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
    var limit: Int
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
