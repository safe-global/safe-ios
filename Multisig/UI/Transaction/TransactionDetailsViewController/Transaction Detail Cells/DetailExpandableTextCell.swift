//
//  DetailExpandableTextCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailExpandableTextCell: UITableViewCell {
    weak var tableView: UITableView?

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var expandableIconImageView: UIImageView!
    @IBOutlet private weak var expandableTitleLabel: UILabel!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var contentCopyButton: UIButton!
    @IBOutlet private weak var expanableContainerStackView: UIStackView!
    @IBOutlet private weak var expandButton: UIButton!
    private var textToCopy: String?
    private var isExpanded: Bool = false

    var titleStyle: GNOTextStyle = .headline
    var expandableTitleStyle: (collapsed: GNOTextStyle, expanded: GNOTextStyle) = (.body, .body)
    var contentStyle: (collapsed: GNOTextStyle, expanded: GNOTextStyle) = (.body, .bodyPrimary)

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(titleStyle)
        expandableTitleLabel.setStyle(expandableTitleStyle.collapsed)
        expandableIconImageView.tintColor = .labelSecondary
        setExpandableTitle(nil)
        setCopyText(nil)
        updateExpanded()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isExpanded = false
        titleStyle = .headline
        expandableTitleStyle = (.body, .body)
        contentStyle = (.body, .bodyPrimary)
        titleLabel.setStyle(titleStyle)
        contentLabel.setStyle(contentStyle.collapsed)
        expandableTitleLabel.setStyle(expandableTitleStyle.collapsed)
    }

    func setText(_ text: String) {
        contentLabel.text = text
    }

    func setTitle(_ text: String?) {
        titleLabel.text = text
        titleLabel.isHidden = text == nil
        titleLabel.setStyle(titleStyle)
    }

    func set(isExpandable: Bool) {
        expanableContainerStackView.isHidden = !isExpandable
        expandButton.isEnabled = isExpandable
    }

    // nil argument indicates that the cell is not expandable, i.e. it will show the main content
    func setExpandableTitle(_ text: String?) {
        let isExpandable: Bool = text == nil
        expanableContainerStackView.isHidden = isExpandable
        expandableTitleLabel.text = text
        expandableTitleLabel.setStyle(expandableTitleStyle.collapsed)
        let contentStyle: GNOTextStyle = isExpandable && !isExpanded ? contentStyle.collapsed : contentStyle.expanded
        contentLabel.setStyle(contentStyle)
        contentLabel.isHidden = isExpandable ? false : !isExpanded
    }

    func setCopyText(_ copyText: String?) {
        contentCopyButton.isHidden = copyText == nil
        textToCopy = copyText
    }

    @IBAction private func didTapExpandButton(_ sender: Any) {
        isExpanded.toggle()
        updateExpanded()
    }

    private func updateExpanded() {
        let image = UIImage(systemName: isExpanded ? "chevron.up" : "chevron.down")?
            .applyingSymbolConfiguration(.init(weight: .bold))
        expandableIconImageView.image = image

        tableView?.beginUpdates()
        contentLabel.isHidden = !isExpanded
        contentLabel.setStyle(isExpanded ? contentStyle.expanded : contentStyle.collapsed)
        expandableTitleLabel.setStyle(isExpanded ? expandableTitleStyle.expanded : expandableTitleStyle.collapsed)
        tableView?.endUpdates()
    }

    @IBAction private func didTapCopyButton(_ sender: Any) {
        Pasteboard.string = textToCopy
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    @IBAction private func copyTouchDown(_ sender: Any) {
        alpha = 0.7
    }

    @IBAction private func copyTouchUp(_ sender: Any) {
        alpha = 1.0
    }
}
