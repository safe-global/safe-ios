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
        case step
        case finalStep
    }
    var onClose: () -> Void = {}
    
    var steps: [Step] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "How does it work?"
        
        steps = [.header,
                    .step,
                    .step,
                    .step,
                    .step,
                    .step,
                    .finalStep]
        
        tableView.registerCell(InstructionHeaderTableViewCell.self)
        tableView.registerCell(FinalStepInstructionTableViewCell.self)
        tableView.registerCell(StepInstructionTableViewCell.self)
        
        button.setText("OK, Let’s start", .filled)
    }
    
    override func closeModal() {
        onClose()
    }
    
    @IBAction func didTapButton(_ sender: Any) {
        let createSafeVC = CreateSafeViewController()
        createSafeVC.onClose = onClose
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
        case .step:
            let cell = tableView.dequeueCell(StepInstructionTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            cell.separatorInset.left = .greatestFiniteMagnitude
            return cell
        case .finalStep:
            let cell = tableView.dequeueCell(FinalStepInstructionTableViewCell.self, for: indexPath)
            cell.cellLabel.text = "Start using your Safe!"
            cell.selectionStyle = .none
            cell.separatorInset.left = .greatestFiniteMagnitude
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        steps.count
    }
}
