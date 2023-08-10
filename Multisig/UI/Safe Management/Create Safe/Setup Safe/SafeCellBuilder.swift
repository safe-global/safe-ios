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
        tableView.registerCell(WarningTableViewCell.self)
    }

    func helpTextCell(_ text: String, hyperlink: String, indexPath: IndexPath) -> HelpTextTableViewCell {
        let cell = tableView.dequeueCell(HelpTextTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.cellLabel.hyperLinkLabel(
            text,
            prefixStyle: .footnote,
            linkText: hyperlink,
            linkStyle: .footnotePrimary,
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
        let link = "Learn about Safe Account setup"
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

    func warningCell(image: UIImage? = nil,
                     title: String? = nil,
                     description: String? = nil,
                     backgroundColor: UIColor = .warningBackground,
                     for indexPath: IndexPath) -> WarningTableViewCell {
        let cell = tableView.dequeueCell(WarningTableViewCell.self, for: indexPath)
        cell.set(image: image, title: title, description: description, backgroundColor: backgroundColor)

        return cell
    }
}
