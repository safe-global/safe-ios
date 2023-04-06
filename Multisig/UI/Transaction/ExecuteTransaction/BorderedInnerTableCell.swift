//
//  BorderedInnerTableCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class BorderedInnerTableCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!

    var cells: [UITableViewCell] = []
    var onCellTap: (Int) -> Void = { _ in }

    var verticalSpacing: CGFloat = 0 {
        didSet {
            topConstraint.constant = verticalSpacing
            bottomConstraint.constant = verticalSpacing
            setNeedsUpdateConstraints()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.layer.borderWidth = 1
        tableView.layer.cornerRadius = 8
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        // disable scrolling since we will show the full content
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        tableView.layer.borderColor = (selected ? UIColor.primary : UIColor.border).cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // appearance will be updated based on the light/dark mode system environment changes
        tableView.layer.borderColor = (isSelected ? UIColor.primary : UIColor.border).cgColor
    }

    func setCells(_ cells: [UITableViewCell]) {
        self.cells = cells
        tableView.reloadData()

        // adjust the table height to show full content
        let height = cells.map { $0.frame.height }.reduce(0, +)
        self.tableHeightConstraint.constant = height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onCellTap(indexPath.row)
    }
}
