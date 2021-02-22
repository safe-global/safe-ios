//
//  PasscodeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/22/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class PasscodeViewController: UIViewController {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var headlineStackView: UIStackView!
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var symbolsStack: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        headlineLabel.setStyle(.headline)
        promptLabel.setStyle(.primary)
        errorLabel.setStyle(.error)
        detailLabel.setStyle(.secondary)
        button.setText("Skip", .plain)
        textField.becomeFirstResponder()
    }

    @IBAction func didTapButton(_ sender: Any) {
    }
}

extension PasscodeViewController: UITextFieldDelegate {

}


class CreatePasscodeViewController: PasscodeViewController {
    convenience init() {
        self.init(namedClass: PasscodeViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Create Passcode"
    }
    
    override func didTapButton(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
