//
//  InactiveLinkViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InactiveLinkViewController: UIViewController {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var doneLabel: UIButton!

    var onDone: () -> Void = { }

    convenience init(completion: @escaping () -> Void) {
        self.init()
        onDone = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.makeTransparentNavigationBar(self)
        ViewControllerFactory.addCloseButton(self)

        titleLabel.setStyle(.title3.weight(.semibold))
        titleLabel.text = "This link is no longer active"

        bodyLabel.setStyle(.secondary)
        bodyLabel.text = "The new owner has already been added by someone else."

        doneLabel.setText("Got it", .filled)
    }

    override func closeModal() {
        onDone()
    }

    @IBAction func didTapDone(_ sender: Any) {
        onDone()
    }
}
