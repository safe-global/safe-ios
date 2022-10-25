//
//  ActionDetailExpandableCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ActionDetailExpandableCell: ActionDetailTableViewCell {
    var subcells: [UITableViewCell] = []

    @IBOutlet private weak var cellLabel: UILabel!
    @IBOutlet private weak var rightImageView: UIImageView!

    private static let symbol = UIImage.SymbolConfiguration(
        pointSize: 17,
        weight: .bold,
        scale: .medium)

    private static let collapsedImage = UIImage(
        systemName: "chevron.down",
        withConfiguration: symbol)!
        .withTintColor(.labelSecondary)

    private static let expandedImage = UIImage(
        systemName: "chevron.up",
        withConfiguration: symbol)!
        .withTintColor(.labelSecondary)

    enum State {
        case collapsed, expanded
    }

    var state = State.collapsed {
        didSet {
            updateUIState()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        cellLabel.setStyle(.body)
        updateUIState()
    }

    private func updateUIState() {
        switch state {
        case .collapsed:
            rightImageView.image = Self.collapsedImage
        case .expanded:
            rightImageView.image = Self.expandedImage
        }
    }

    func setText(_ text: String?) {
        cellLabel.text = text
    }
}
