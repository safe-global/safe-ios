//
//  ErrorViewController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 06.06.24.
//  Copyright © 2024 Core Contributors GmbH. All rights reserved.
//

import UIKit

class ErrorViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var button: UIButton!

    var titleText = "Operation failed"
    var bodyText = "Error details are below:"
    var errorText = ""
    var buttonTitle = "Done"
    
    var completion: () -> Void = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = titleText
        descriptionLabel.text = bodyText
        textView.text = errorText
        button.setText(buttonTitle, .filled)
        
        titleLabel.setStyle(.headline)
        descriptionLabel.setStyle(.body)
        textView.setStyle(.bodyMedium)
    }
    
    @IBAction func done(_ sender: Any) {
        completion()
    }
    
}
