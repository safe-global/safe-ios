//
//  EnableNotificationViewController.swift
//  Multisig
//
//  Created by Mouaz on 6/23/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeActionViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var secondaryActionButton: UIButton!
    @IBOutlet private weak var primaryActionButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!

    var titleText: String?
    var descriptionText: String?
    var primaryActionTitle: String?
    var secondaryActionTitle: String?
    var imageName: String?
    
    var onPrimaryAction: () -> () = {}
    var onSecondaryAction: () -> () = {}

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(titleText != nil)
        assert(descriptionText != nil)
        assert(primaryActionTitle != nil)
        assert(secondaryActionTitle != nil)
        assert(imageName != nil)

        titleLabel.text = titleText
        descriptionLabel.text = descriptionText

        imageView.image = UIImage(named: imageName!)
        titleLabel.setStyle(.title1)
        descriptionLabel.setStyle(.body)
        primaryActionButton.setText(primaryActionTitle, .filled)
        secondaryActionButton.setText(secondaryActionTitle, .primary)
    }

    @IBAction func primaryActionTouched(_ sender: Any) {
        onPrimaryAction()
    }

    @IBAction func secondaryActionTouched(_ sender: Any) {
        onSecondaryAction()
    }
}
