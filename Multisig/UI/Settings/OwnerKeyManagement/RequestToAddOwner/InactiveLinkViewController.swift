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

    var titleText: String?
    var bodyText: String?
    var buttonText: String = "OK"
    var onDone: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.makeTransparentNavigationBar(self)
        ViewControllerFactory.addCloseButton(self)

        titleLabel.setStyle(.title3.weight(.semibold))
        titleLabel.text = titleText

        bodyLabel.setStyle(.body)
        bodyLabel.text = bodyText

        doneLabel.setText(buttonText, .filled)
    }

    override func closeModal() {
        onDone()
    }

    @IBAction func didTapDone(_ sender: Any) {
        onDone()
    }

    static func inactiveLink(completion: @escaping () -> Void) -> InactiveLinkViewController {
        let vc = InactiveLinkViewController()
        vc.titleText = "This link is no longer active"
        vc.bodyText = "The new owner has already been added by someone else."
        vc.buttonText = "Got it"
        vc.onDone = completion
        return vc
    }

    static func broken(_ error: Error, completion: @escaping () -> Void) -> InactiveLinkViewController {
        let vc = InactiveLinkViewController()
        vc.titleText = "Something went wrong"
        vc.bodyText = error.localizedDescription
        vc.buttonText = "Close"
        vc.onDone = completion
        return vc
    }
}
