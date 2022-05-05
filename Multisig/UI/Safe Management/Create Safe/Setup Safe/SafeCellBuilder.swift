//
//  SafeCellBuilder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class SafeCellBuilder {
    weak var viewController: UIViewController!
    weak var tableView: UITableView!

    init(viewController: UIViewController, tableView: UITableView) {
        self.viewController = viewController
        self.tableView = tableView
    }

    func registerCells() {
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        tableView.registerCell(HelpTextTableViewCell.self)
        tableView.registerCell(StepperTableViewCell.self)
    }

    func helpTextCell(_ text: String, hyperlink: String, indexPath: IndexPath) -> HelpTextTableViewCell {
        let cell = tableView.dequeueCell(HelpTextTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.cellLabel.hyperLinkLabel(
            text,
            prefixStyle: .footnote2.weight(.regular),
            linkText: hyperlink,
            linkStyle: .footnote2.weight(.regular).color(.primary),
            linkIcon: nil)
        return cell
    }

    func thresholdCell(_ text: String, range: ClosedRange<Int>, value: Int, indexPath: IndexPath, onChange: @escaping (_ threshold: Int) -> Void) -> StepperTableViewCell {
        let cell = tableView.dequeueCell(StepperTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.setText(text)
        cell.setRange(min: range.lowerBound, max: range.upperBound)
        cell.setValue(value)
        cell.onChange = onChange
        return cell
    }

    func thresholdHelpCell(for indexPath: IndexPath) -> HelpTextTableViewCell {
        let text = "How many owner confirmations are required for a transaction to be executed?"
        let link = "Learn about Safe setup"
        return helpTextCell(text, hyperlink: link, indexPath: indexPath)
    }

    func didSelectThresholdHelpCell() {
        viewController.openInSafari(App.configuration.help.confirmationsURL)
    }

    func headerView(text: String) -> BasicHeaderView {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(text)
        return view
    }
}
