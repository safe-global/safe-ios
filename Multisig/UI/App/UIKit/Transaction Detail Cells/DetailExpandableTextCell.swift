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
    @IBOutlet private weak var expandableTitleButton: UIButton!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var contentCopyButton: UIButton!
    private var textToCopy: String?
    private var isExpanded: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
        expandableTitleButton.titleLabel?.setStyle(GNOTextStyle.body.color(.gnoDarkGrey))
        setExpandableTitle(nil)
        setCopyText(nil)
        updateExpanded()
    }

    func setText(_ text: String) {
        contentLabel.text = text
    }

    func setTitle(_ text: String) {
        titleLabel.text = text
    }

    func setExpandableTitle(_ text: String?) {
        let isExpandable: Bool = text == nil
        expandableTitleButton.isHidden = isExpandable
        expandableTitleButton.setTitle(text, for: .normal)
        let contentStyle = isExpandable ? GNOTextStyle.body.color(.gnoDarkGrey) : .body
        contentLabel.setStyle(contentStyle)
        contentLabel.isHidden = isExpandable ? false : !isExpanded
    }

    func setCopyText(_ copyText: String?) {
        contentCopyButton.isHidden = copyText == nil
        textToCopy = copyText
    }

    @IBAction private func didTapExpandableTitle(_ sender: Any) {
        isExpanded.toggle()
        updateExpanded()
    }

    private func updateExpanded() {
        let image = UIImage(systemName: isExpanded ? "chevron.up" : "chevron.down")?
            .applyingSymbolConfiguration(.init(weight: .bold))
        expandableTitleButton.setImage(image, for: .normal)

        tableView?.beginUpdates()
        contentLabel.isHidden = !isExpanded
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
