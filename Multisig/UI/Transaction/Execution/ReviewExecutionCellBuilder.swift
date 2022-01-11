//
//  ReviewExecutionCellBuilder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ReviewExecutionCellBuilder: TransactionDetailCellBuilder {

    var onTapAccount: () -> Void = {}
    var onTapFee: () -> Void = {}
    var onTapAdvanced: () -> Void = {}

    override init(vc: UIViewController, tableView: UITableView, chain: Chain) {
        super.init(vc: vc, tableView: tableView, chain: chain)

        tableView.registerCell(BorderedInnerTableCell.self)
    }

    func build(_ model: ExecutionReviewUIModel) -> [UITableViewCell] {
        result = []
        // nothing to do for creation transaction
        if case let SCGModels.TxInfo.creation(_) = model.transaction.txInfo {
            return result
        }
        buildHeader(model.transaction)
        buildAssetContract(model.transaction)
        buildExecutionOptions(model.executionOptions)
        return result
    }

    func buildExecutionOptions(_ model: ExecutionOptionsUIModel) {
        // create a table inner cell with other cells:
//            buildExecutedWithAccount(model.accountState)
//            buildEstimatedGasFee(model.feeState)
//            buildAdvancedParameters()
        let tableCell = newCell(BorderedInnerTableCell.self)

        tableCell.tableView.registerCell(SecondaryDetailDisclosureCell.self)

        let disclosureCell1 = tableCell.tableView.dequeueCell(SecondaryDetailDisclosureCell.self)
        disclosureCell1.setText("Hello world 1")

        let disclosureCell2 = tableCell.tableView.dequeueCell(SecondaryDetailDisclosureCell.self)
        disclosureCell2.setText("Hello world 2")

        let disclosureCell3 = tableCell.tableView.dequeueCell(SecondaryDetailDisclosureCell.self)
        disclosureCell3.setText("Hello world 3")

        tableCell.setCells([disclosureCell1, disclosureCell2, disclosureCell3])

        result.append(tableCell)
    }

    func buildExecutedWithAccount(_ model: ExecuteWithAccountCellState) {
        // detailed disclosure cell
        // text set to "Execute with"
        // content set to AccountAndBalance piece
            // 'loading' status for automatic selection process
                // skeleton loading view
            // 'empty' with call to action to select something
                // label
            // 'filled' state for the account and balance
                // account and balance piece

        // onTap -> call the 'onTapAccount'
    }

    func buildEstimatedGasFee(_ model: EstimatedFeeCellState) {
        // detailed disclosure cell
        // text set to "Estimated gas fee"

        // 'loading'
            // skeleton / loading view
        // 'loaded'
            // amount and value piece

        // onTap -> call the 'onTapFee'
    }

    func buildAdvancedParameters() {
        // secondary detail disclosure cell
        // text is "Advanced parameters"
        // onTap -> call the 'onTapAdvanced'
    }

    // New cell types:

    // detailed disclosure cell

    // secondary disclosure cell

}

struct ExecutionReviewUIModel {
    var transaction: SCGModels.TransactionDetails
    var executionOptions: ExecutionOptionsUIModel
}

struct ExecutionOptionsUIModel {
    var accountState: ExecuteWithAccountCellState = .loading
    var feeState: EstimatedFeeCellState = .loading
}

enum ExecuteWithAccountCellState {
    case loading
    case empty
    case filled(MiniAccountInfoUIModel)
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
    case loaded(EstimatedFeeUIModel)
}

struct EstimatedFeeUIModel {
    var tokenAmount: String
    var fiatAmount: String?
}
