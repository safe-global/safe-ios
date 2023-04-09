//
//  SendTransactionContentViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import Ethereum
import SwiftCryptoTokenFormatter

class SendTransactionContentViewController: UITableViewController {
    private var cells: [UITableViewCell] = []
    private var builder = SendTransactionCellBuilder()

    var onTapAccount: () -> Void = {}
    var onTapFee: () -> Void = {}

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48
        tableView.backgroundColor = .backgroundSecondary
        tableView.tableFooterView = UIView()
        builder.register(tableView: tableView)
    }

    func reloadData(transaction: EthTransaction,
                    keyInfo: KeyInfo,
                    chain: Chain,
                    balance: UInt256?,
                    fee: UInt256?,
                    error: String?) {

        builder.chain = chain
        builder.key = keyInfo
        builder.balance = balance
        builder.fee = fee
        builder.to = Address(transaction.to)
        builder.value = transaction.value.big()
        builder.data = transaction.data.storage
        builder.errorMessage = error
        builder.onTapAccount = onTapAccount
        builder.onTapFee = onTapFee

        cells = builder.build()
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if let disclosureCell = cell as? DetailDisclosingCell {
            disclosureCell.action()
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        return cell is DetailDisclosingCell ? indexPath : nil
    }
}

class SendTransactionCellBuilder {
    weak var tableView: UITableView!

    var value: UInt256!
    var chain: Chain!
    var to: Address!
    var data: Data!
    var key: KeyInfo!
    var balance: UInt256?
    var fee: UInt256?
    var errorMessage: String?

    var result: [UITableViewCell] = []
    var onTapAccount: () -> Void = {}
    var onTapFee: () -> Void = {}

    func register(tableView: UITableView) {
        self.tableView = tableView
        tableView.registerCell(BorderedInnerTableCell.self)
        tableView.registerCell(ErrorTableViewCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(DetailMultiAccountsCell.self)
    }

    func build() -> [UITableViewCell] {

        result = []

        if let nativeCurrency = chain.nativeCurrency {
            let amountModel = TokenAmountUIModel(
                value: value,
                symbol: nativeCurrency.symbol!,
                decimals: UInt64(nativeCurrency.decimals),
                tokenLogoUri: nativeCurrency.logoUrl?.absoluteString
            )
            buildAmount(amountModel: amountModel)
        }

        let namingPolicy = NamingPolicy.name(for: to, info: nil, chainId: chain.id!)

        address(
            to,
            label: namingPolicy.name,
            title: "To",
            imageUri: namingPolicy.imageUri,
            browseURL: chain.browserURL(address: to.checksummed),
            prefix: chain.shortName
        )

        text(data.toHexStringWithPrefix(), title: "Data", expandableTitle: "\(data.count) Bytes", copyText: data.toHexStringWithPrefix())

        var accountState = ExecuteWithAccountCellState.loading
        if let balance = balance {
            let keyNamePolicy = NamingPolicy.name(for: key.address, info: nil, chainId: chain.id!)

            let accountInfo = MiniAccountInfoUIModel(
                prefix: chain.shortName,
                address: key.address,
                label: keyNamePolicy.name,
                imageUri: keyNamePolicy.imageUri,
                badge: key.keyType.badgeName,
                balance: formatAmount(chain: chain, balance: balance)
            )
            accountState = ExecuteWithAccountCellState.filled(accountInfo)
        }

        var feeState = EstimatedFeeCellState.loading
        if let fee = fee {
            let feeInfo = EstimatedFeeUIModel(tokenAmount: formatAmount(chain: chain, balance: fee), fiatAmount: nil)
            feeState = EstimatedFeeCellState.loaded(feeInfo)
        }

        let options = ExecutionOptionsUIModel(
            accountState: accountState,
            feeState: feeState
        )

        buildExecutionOptions(options)

        buildErrors(errorMessage)

        return result
    }

    func formatAmount(chain: Chain, balance: UInt256) -> String {
        let nativeCoinDecimals = chain.nativeCurrency!.decimals
        let nativeCoinSymbol = chain.nativeCurrency!.symbol!

        let decimalAmount = BigDecimal(Int256(balance), Int(nativeCoinDecimals))
        let value = TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
            forcePlusSign: false
        )

        return "\(value) \(nativeCoinSymbol)"
    }

    func text(_ text: String, title: String, expandableTitle: String?, copyText: String?) {
        let cell = tableView.dequeueCell(DetailExpandableTextCell.self)
        cell.tableView = tableView
        cell.setTitle(title)
        cell.setText(text)
        cell.setCopyText(copyText)
        cell.setExpandableTitle(expandableTitle)
        result.append(cell)
    }

    func buildAmount(amountModel: TokenAmountUIModel) {
        let cell = tableView.dequeueCell(DetailMultiAccountsCell.self)
        let tokenView = TokenInfoView()
        tokenView.setTitle("Amount")
        tokenView.setImage(amountModel.tokenLogoURL, placeholder: amountModel.placeholder)
        tokenView.setText(amountModel.formattedAmount)
        tokenView.setDetail(amountModel.formattedFiatValue, style: .caption1.weight(.medium))
        cell.setViews([tokenView])
        result.append(cell)
    }

    func address(_ address: Address,
                 label: String?,
                 title: String?,
                 imageUri: URL? = nil,
                 browseURL: URL? = nil,
                 prefix: String? = nil) {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        cell.setAccount(address: address,
                        label: label,
                        title: title,
                        imageUri: imageUri,
                        browseURL: browseURL,
                        prefix: prefix)
        result.append(cell)
    }

    func buildExecutionOptions(_ model: ExecutionOptionsUIModel) {
        // create a table inner cell with other cells
        let tableCell = tableView.dequeueCell(BorderedInnerTableCell.self)

        tableCell.tableView.registerCell(DisclosureWithContentCell.self)
        tableCell.tableView.registerCell(SecondaryDetailDisclosureCell.self)

        let accountCell = buildExecutedWithAccount(model.accountState, tableView: tableCell.tableView)
        accountCell.accessoryType = .none

        let estimatedFeeCell = buildEstimatedGasFee(model.feeState, tableView: tableCell.tableView)

        tableCell.setCells([accountCell, estimatedFeeCell])

        // handle cell taps
        let (executeWithIndex, feeIndex) = (0, 1)
        tableCell.onCellTap = { [weak self] index in
            guard let self = self else { return }
            switch index {
            case executeWithIndex:
                self.onTapAccount()
            case feeIndex:
                self.onTapFee()
            default:
                assertionFailure("Tapped cell at index out of bounds: \(index)")
            }
        }

        result.append(tableCell)
    }


    func buildExecutedWithAccount(_ model: ExecuteWithAccountCellState, tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Execute with")
        switch model {

        case .none:
            preconditionFailure("Developer error: CellState not properly initialized")

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
        cell.setText("Estimated fee")

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
    
    func buildErrors(_ errorText: String?) {
        guard var errorText = errorText else {
            return
        }

        errorText = "!⃤ " + errorText
        // restrict to 1 tweet length
        let errorPreview = errorText.count <= 144 ? nil : (String(errorText.prefix(144)) + "…")

        let cell = tableView.dequeueCell(DetailExpandableTextCell.self)
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

}
