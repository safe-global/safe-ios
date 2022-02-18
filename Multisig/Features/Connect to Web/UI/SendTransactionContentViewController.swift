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

class SendTransactionContentViewController: UITableViewController {
    private var cells: [UITableViewCell] = []
    private var builder = SendTransactionCellBuilder()

    var onTapAccount: () -> Void = {}
    var onTapFee: () -> Void = {}


    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48
        builder.register(tableView: tableView)

        reloadData()
    }

    func reloadData() {
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

    var value: UInt256?
    var chain: Chain?
    var to: Address?
    var data: Data?
    var key: KeyInfo?
    var balance: UInt256?
    var fee: UInt256?

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

        // amount
        // value, chain
        let amountModel = TokenAmountUIModel(
            value: <#T##UInt256?#>,
            symbol: <#T##String#>,
            decimals: <#T##UInt64?#>,
            tokenLogoUri: <#T##String?#>
        )
        buildAmount(amountModel: amountModel)

        // to
        // address, chain
        address(
            <#T##address: Address##Address#>,
            label: <#T##String?#>,
            title: <#T##String?#>,
            imageUri: <#T##URL?#>,
            browseURL: <#T##URL?#>,
            prefix: <#T##String?#>
        )

        // data
        // hex data
        text(<#T##String#>, title: "Data", expandableTitle: <#T##String?#>, copyText: <#T##String?#>)

        // table
            // execute with
            // estimated gas fee
        // key address, balance
        let accountInfo = MiniAccountInfoUIModel(
            prefix: <#T##String?#>,
            address: <#T##Address#>,
            label: <#T##String?#>,
            imageUri: <#T##URL?#>,
            badge: <#T##String?#>,
            balance: <#T##String?#>
        )
        let accountState = ExecuteWithAccountCellState.filled(accountInfo)

        // estimated total fee formatted with native currency balance.
        let feeInfo = EstimatedFeeUIModel(tokenAmount: <#T##String#>, fiatAmount: nil)
        let feeState = EstimatedFeeCellState.loaded(feeInfo)

        let options = ExecutionOptionsUIModel(
            accountState: accountState,
            feeState: feeState
        )
        buildExecutionOptions(options)

        // errors
        buildErrors(<#T##errorText: String?##String?#>)

        return result
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

        let disclosureCell1 = buildExecutedWithAccount(model.accountState, tableView: tableCell.tableView)
        let estimatedFeeCell = buildEstimatedGasFee(model.feeState, tableView: tableCell.tableView)

        tableCell.setCells([disclosureCell1, estimatedFeeCell])

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
        label.setStyle(.secondary)
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
        guard let errorText = errorText else {
            return
        }

        // restrict to 1 tweet length
        let errorPreview = errorText.count <= 144 ? nil : (String(errorText.prefix(144)) + "…")

        let cell = tableView.dequeueCell(DetailExpandableTextCell.self)
        cell.tableView = tableView
        cell.titleStyle = .error.weight(.medium)
        cell.expandableTitleStyle = (collapsed: .error, expanded: .error)
        cell.contentStyle = (collapsed: .error, expanded: .secondary)
        cell.setTitle("⚠️ Error")
        cell.setText(errorText)
        cell.setCopyText(errorText)
        cell.setExpandableTitle(errorPreview)

        result.append(cell)
    }

}
