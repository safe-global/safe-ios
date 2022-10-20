//
//  EditAdvancedParametersUITableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 1/6/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class EditAdvancedParametersUITableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var chevronImageView: UIImageView!
    @IBOutlet private weak var nonceInfoLabel: InfoLabel!
    @IBOutlet private weak var nonceLabel: UILabel!
    @IBOutlet private weak var safeTxGasInfoLabel: InfoLabel!
    @IBOutlet private weak var safeTxGasLabel: UILabel!
    @IBOutlet private weak var parametersContainerView: UIStackView!
    @IBOutlet private weak var safeTxGasContainerView: UIStackView!
    @IBOutlet private weak var editButton: UIButton!

    private var isExpanded: Bool = false
    weak var tableView: UITableView?
    var onEdit: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.setStyle(.headline)
        nonceInfoLabel.setText("Safe nonce",
                               description: "Safe nonce determines an order in which transactions are executed.",
                               style: .headline)
        safeTxGasInfoLabel.setText("SafeTxGas",
                                   description: "SafeTxGas specifies the gas that should be used for the Safe transaction.",
                                   style: .headline)
        nonceLabel.setStyle(.headline)
        safeTxGasLabel.setStyle(.headline)
        editButton.setText("Edit", .plain)
        updateExpanded()
    }

    func set(nonce: String) {
        nonceLabel.text = nonce
    }

    func set(safeTxGas: String?) {
        safeTxGasLabel.text = safeTxGas
        safeTxGasContainerView.isHidden = safeTxGas == nil
    }

    @IBAction private func editButtonTouched(_ sender: Any) {
        onEdit?()
    }

    @IBAction private func collapseButtonTouched(_ sender: Any) {
        isExpanded.toggle()
        updateExpanded()
    }

    private func updateExpanded() {
        let image = UIImage(systemName: isExpanded ? "chevron.up" : "chevron.down")?
            .applyingSymbolConfiguration(.init(weight: .bold))
        chevronImageView.image = image

        tableView?.beginUpdates()
        parametersContainerView.isHidden = !isExpanded
        tableView?.endUpdates()
    }
}
