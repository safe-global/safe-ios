//
//  ShareAddOwnerLinkViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/12/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ShareAddOwnerLinkViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet private weak var shareLinkView: ShareTextView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var doneButton: UIButton!

    var steps: [Step] = []
    var onFinish: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.setStyle(.title5)
        doneButton.setText("Done", .filled)

        tableView.registerCell(InstructionHeaderTableViewCell.self)
        tableView.registerCell(FinalStepInstructionTableViewCell.self)
        tableView.registerCell(StepInstructionTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }

    @IBAction func doneButtonTouched(_ sender: Any) {
        onFinish?()
    }
}

extension ShareAddOwnerLinkViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentStep = steps[indexPath.row]
        let cell = tableView.dequeueCell(StepInstructionTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.separatorInset.left = .greatestFiniteMagnitude
        cell.circleLabel.text = number
        cell.headerLabel.text = title
        cell.descriptionLabel.text = description
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        steps.count
    }
}
