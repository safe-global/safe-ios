//
//  AddKeyAsNewOwnerViewController.swift
//  Multisig
//
//  Created by Vitaly on 25.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddKeyAsOwnerIntroViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!

    var onAdd: (() -> ())?

    var onReplace: (() -> ())?

    var onSkip: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        presentationController?.delegate = self

        titleLabel.setStyle(.title2)
        descriptionLabel.setStyle(.body)
        addButton.setText("Add as owner", .filled)
        skipButton.setText("Skip", .plain)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.addAsOwnerIntro)
    }

    // Called when user swipes down the modal screen
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didSkip()
    }

    @IBAction func didTapAddButton(_ sender: Any) {
        addOwnerAction()
    }

    @IBAction func didTapSkipButton(_ sender: Any) {
        didSkip()
    }

    func didSkip() {
        Tracker.trackEvent(.addAsOwnerIntroSkipped)
        onSkip?()
    }

    func addOwnerAction() {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .multiplatformActionSheet)

        let add = UIAlertAction(title: "Add new owner", style: .default) { [unowned self] _ in
            onAdd?()
        }

        let replace = UIAlertAction(title: "Replace owner", style: .default) { [unowned self] _ in
            onReplace?()
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(add)
        alertController.addAction(replace)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}
