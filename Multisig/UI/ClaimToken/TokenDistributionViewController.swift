//
//  TokenDistributionViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class TokenDistributionViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!

    private var onNext: (() -> ())?
    private var stepNumber: Int = 1
    private var maxSteps: Int = 3

    private var stepLabel: UILabel!

    convenience init(stepNumber: Int = 1, maxSteps: Int = 4, onNext: @escaping () -> ()) {
        self.init(namedClass: TokenDistributionViewController.self)
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.onNext = onNext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(BorderedInnerTableCell.self)
        tableView.reloadData()
        titleLabel.setStyle(.Updated.title)
        descriptionLabel.setStyle(.secondary)
        nextButton.setText("Next", .filled)
        
        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"
    }

    @IBAction func didTapNext(_ sender: Any) {
        onNext?()
    }
}

extension TokenDistributionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueCell(BorderedInnerTableCell.self)

        tableCell.selectionStyle = .none
        tableCell.verticalSpacing = 16

        tableCell.tableView.registerCell(DisclosureWithContentCell.self)

        let cell = tableCell.tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Distribution details")
        cell.selectionStyle = .none
        cell.setContent(nil)

        tableCell.setCells([cell])
        tableCell.onCellTap = { [unowned self] _ in

        }

        return tableCell
    }


}
