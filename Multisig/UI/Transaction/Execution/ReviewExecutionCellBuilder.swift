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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Spacer")
    }

    func build(_ model: ExecutionReviewUIModel) -> [UITableViewCell] {
        result = []
        // nothing to do for creation transaction
        if case let SCGModels.TxInfo.creation(_) = model.transaction.txInfo {
            return result
        }
        buildHeader(model.transaction)
        buildAssetContract(model.transaction)
        buildSpacing()
        buildExecutionOptions(model.executionOptions)
        return result
    }

    func buildSpacing() {
        let cell = newCell(UITableViewCell.self, reuseId: "Spacer")
        result.append(cell)
    }

    func buildExecutionOptions(_ model: ExecutionOptionsUIModel) {
        // create a table inner cell with other cells
        let tableCell = newCell(BorderedInnerTableCell.self)

        tableCell.tableView.registerCell(DisclosureWithContentCell.self)
        tableCell.tableView.registerCell(SecondaryDetailDisclosureCell.self)

        let disclosureCell1 = buildExecutedWithAccount(model.accountState, tableView: tableCell.tableView)
        let estimatedFeeCell = buildEstimatedGasFee(model.feeState, tableView: tableCell.tableView)
        let advancedCell = buildAdvancedParameters(tableView: tableCell.tableView)

        tableCell.setCells([disclosureCell1, estimatedFeeCell, advancedCell])

        // handle cell taps
        let (executeWithIndex, feeIndex, advancedIndex) = (0, 1, 2)
        tableCell.onCellTap = { [weak self] index in
            guard let self = self else { return }
            switch index {
            case executeWithIndex:
                self.onTapAccount()
            case feeIndex:
                self.onTapFee()
            case advancedIndex:
                self.onTapAdvanced()
            default:
                assertionFailure("Tapped cell at index out of bounds: \(index)")
            }
        }

        result.append(tableCell)
    }

    func buildExecutedWithAccount(_ model: ExecuteWithAccountCellState, tableView: UITableView) -> UITableViewCell {
        // 'loading' status for automatic selection process
            // skeleton loading view
        // 'empty' with call to action to select something
            // label
        // 'filled' state for the account and balance
            // account and balance piece

        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Execute with")
        switch model {
        case .loading:
            break
        case .empty:
            break
        case .filled(let accountModel):
            let detail = MiniAccountAndBalancePiece()
            detail.setModel(accountModel)
            cell.setContent(detail)
        }
        return cell
    }

    func buildEstimatedGasFee(_ model: EstimatedFeeCellState, tableView: UITableView) -> UITableViewCell {
        // 'loading'
            // skeleton / loading view
        // 'loaded'
            // amount and value piece

        let estimatedFeeCell = tableView.dequeueCell(DisclosureWithContentCell.self)
        estimatedFeeCell.setText("Estimated gas fee")

        let amountPiece = AmountAndValuePiece()
        amountPiece.setAmount("Some amount")
        amountPiece.setFiatAmount("some fiat")

        estimatedFeeCell.setContent(amountPiece)

        return estimatedFeeCell
    }

    func buildAdvancedParameters(tableView: UITableView) -> UITableViewCell {
        let advancedCell = tableView.dequeueCell(SecondaryDetailDisclosureCell.self)
        advancedCell.setText("Advanced parameters")
        return advancedCell
    }
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
