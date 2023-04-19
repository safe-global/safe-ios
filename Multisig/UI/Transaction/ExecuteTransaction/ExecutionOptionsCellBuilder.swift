//
//  ExecutionOptionsCellBuilder.swift
//  Multisig
//
//  Created by Dirk Jäckel on 31.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ExecutionOptionsCellBuilder: TransactionDetailCellBuilder {

    var onTapPaymentMethod: () -> Void = {}
    var onTapAccount: () -> Void = {}
    var onTapFee: () -> Void = {}
    // TODO: double check if this is necessary here
    var onTapAdvanced: () -> Void = {}
    var userSelectedSigner = false

    func buildExecutionOptions(_ model: ExecutionOptionsUIModel) -> [UITableViewCell] {
        var result = [UITableViewCell]()
        let paymentGroupCell = newCell(BorderedInnerTableCell.self)

        paymentGroupCell.tableView.registerCell(DisclosureWithContentCell.self)
        paymentGroupCell.tableView.registerCell(SecondaryDetailDisclosureCell.self)
        paymentGroupCell.tableView.registerCell(PaymentMethodCell.self)
        paymentGroupCell.tableView.separatorStyle = .none

        var sponsoredPayment = false
        if case let .filled(relayerInfo) = model.relayerState,
           relayerInfo.remainingRelays > ReviewExecutionViewController.MIN_RELAY_TXS_LEFT &&
            !userSelectedSigner &&
            chain.isSupported(feature: .relayingMobile) {
            sponsoredPayment = true
        }

        let estimatedFeeCell = buildEstimatedGasFee(model.feeState, tableView: paymentGroupCell.tableView, sponsoredPayment: sponsoredPayment)

        if sponsoredPayment {
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
                if !sponsoredPayment {
                    self.onTapFee()
                }
            case paymentIndex:
                if self.chain.isSupported(feature: .relayingMobile) {
                    self.onTapPaymentMethod()
                }
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

        return result
    }

    func buildEstimatedGasFee(_ model: EstimatedFeeCellState, tableView: UITableView, sponsoredPayment: Bool) -> UITableViewCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Estimated fee")
        cell.setBackgroundColor(.backgroundSecondary)

        if sponsoredPayment {
            cell.accessoryType = .none
        }

        switch model {
        case .loading:
            let content = loadingView()
            cell.setContent(content)

        case .empty:
            let content = textView("Not set")
            cell.setContent(content)

        case .loaded(let feeModel):
            let amountPiece = AmountAndValuePiece()
            amountPiece.setAmount(feeModel.tokenAmount, sponsored: sponsoredPayment)
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

    func buildRelayerPayment(_ model: ExecutionOptionsUIModel, tableView: UITableView) -> UITableViewCell{
        let cell = tableView.dequeueCell(PaymentMethodCell.self)
        if case let .filled(relayerInfo) = model.relayerState {
            cell.setRelaying(relayerInfo.remainingRelays, relayerInfo.limit)
        }
        cell.setBackgroundColor(.backgroundPrimary)
        return cell
    }

    func buildAccountPayment(tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(SecondaryDetailDisclosureCell.self)
        cell.setText("With an owner key", hideDisclousre: !chain.isSupported(feature: .relayingMobile))
        cell.selectionStyle = chain.isSupported(feature: .relayingMobile) ? .default : .none
        cell.setBackgroundColor(.backgroundPrimary)
        return cell
    }

    func buildExecutedWithAccount(_ model: ExecuteWithAccountCellState, tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Select key")
        cell.setBackgroundColor(.backgroundPrimary)
        switch model {
        case .none:
            preconditionFailure("Developer error: CellState not properly initialized")

        case .loading:
            let content = loadingView()
            cell.setContent(content)

        case .empty:
            let content = textView("Key not set")
            cell.setContent(content)

        case .filled(let accountModel):
            let content = MiniAccountAndBalancePiece()
            content.setModel(accountModel)
            cell.setContent(content)
        }
        return cell
    }

    // TODO possible duplication between ReviewExecutionCellBUilder and here
    func buildSpacing() {
        let cell = newCell(UITableViewCell.self, reuseId: "Spacer")
        cell.contentView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        result.append(cell)
    }

    // TODO separate adnvaced parameters from execution options if possible
    func buildAdvancedParameters(tableView: UITableView) -> UITableViewCell {
        let advancedCell = tableView.dequeueCell(SecondaryDetailDisclosureCell.self)
        advancedCell.setText("Advanced parameters")
        advancedCell.setBackgroundColor(.backgroundSecondary)
        return advancedCell
    }
}
