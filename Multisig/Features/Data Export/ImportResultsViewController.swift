//
//  ImportResultsViewController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 29.05.24.
//  Copyright © 2024 Gnosis Ltd. All rights reserved.
//

import UIKit

class ImportResultsViewController: UIViewController {
    
    var logs: [String] = []
    var completion: (() -> Void)?
    
    @IBOutlet weak var logsTextField: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if logs.isEmpty {
            logsTextField.text = "No errors."
        } else {
            logsTextField.text = logs.joined(separator: "\n")
        }
    }

    @IBAction func done() {
        completion?()
    }

}
