//
//  InstructionsViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 22.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InstructionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var tableView: UITableView!

    enum Step {
        case header
        case step(number: String, title: String, description: String)
        case finalStep(title: String)
    }

    var onClose: () -> Void = {}
    var steps: [Step] = []
    var chain: Chain?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "How does it work?"

        tableView.registerCell(InstructionHeaderTableViewCell.self)
        tableView.registerCell(FinalStepInstructionTableViewCell.self)
        tableView.registerCell(StepInstructionTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
        button.setText("OK, Let’s start", .filled)
    }
    
    override func closeModal() {
        onClose()
    }
    
    @IBAction func didTapButton(_ sender: Any) {
        let createSafeVC = CreateSafeViewController()
        createSafeVC.onClose = onClose
        if let chain = chain {
            createSafeVC.chain = chain
        }
        
        show(createSafeVC, sender: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentStep = steps[indexPath.row]
        switch currentStep {
        case .header:
            let cell = tableView.dequeueCell(InstructionHeaderTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            cell.separatorInset.left = .greatestFiniteMagnitude
            return cell
        case let .step(number: number, title: title, description: description):
            let cell = tableView.dequeueCell(StepInstructionTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            cell.separatorInset.left = .greatestFiniteMagnitude
            cell.circleLabel.text = number
            cell.headerLabel.text = title
            cell.descriptionLabel.text = description
            return cell
        case let .finalStep(title: title):
            let cell = tableView.dequeueCell(FinalStepInstructionTableViewCell.self, for: indexPath)
            cell.cellLabel.text = title
            cell.selectionStyle = .none
            cell.separatorInset.left = .greatestFiniteMagnitude
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        steps.count
    }
}
