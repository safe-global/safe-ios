//
//  AddGeneratedKeyAsOwnerIntroViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/9/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddGeneratedKeyAsOwnerIntroViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var notThisTimeButton: UIButton!

    var onAdd: (() -> ())?

    var onSkip: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        presentationController?.delegate = self

        // remove underline from navigationItem
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = .clear
        navigationBarAppearance.shadowColor = .clear
        navigationItem.scrollEdgeAppearance = navigationBarAppearance

        // disable swipe back
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        navigationController?.isNavigationBarHidden = false

        titleLabel.setStyle(.primary)
        descriptionLabel.setStyle(.secondary)
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

    @IBAction func didTapShareButton(_ sender: Any) {
        addOwnerAction()
    }

    @IBAction func didTapNotThisTimeButton(_ sender: Any) {
        Tracker.trackEvent(.addAsOwnerIntroSkipped)
        onSkip?()
    }

    func addOwnerAction() {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)

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
