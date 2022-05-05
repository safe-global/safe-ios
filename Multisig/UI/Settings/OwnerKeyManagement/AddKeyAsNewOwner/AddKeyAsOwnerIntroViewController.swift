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

        // remove underline from navigationItem
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = .clear
        navigationBarAppearance.shadowColor = .clear
        navigationItem.scrollEdgeAppearance = navigationBarAppearance

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
            preferredStyle: .actionSheet)

        let add = UIAlertAction(title: "Add new owner", style: .default) { [unowned self] _ in
            onAdd?()
        }

        let replace = UIAlertAction(title: "Replace owner", style: .default) { [unowned self] _ in
            // TODO use: onReplace?() and remove the following line and the implementation
            replaceOwnerAction()
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(add)
        alertController.addAction(replace)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }

    func replaceOwnerAction() {
        //TODO: navigate to safe owner selection

        guard let safe = try? Safe.getSelected() else { return }
        guard let key = try? KeyInfo.all().first else { return }

        // TODO for now we skip to Review screen
        // TODO select a random owner of the current select safe to be replaced
        let addresses =  safe.ownersInfo!.compactMap { info in
            info.address
        }
        do {
            let ownerToBeReplaced = try KeyInfo.keys(addresses: addresses).first
            let replaceOwnerReviewVC = ReviewReplaceOwnerTxViewController(safe: safe,
                    owner: key,
                    ownersCount: safe.ownersInfo?.count ?? 0,
                    threshold: Int(safe.threshold ?? 0),
                    ownerToBeReplaced: ownerToBeReplaced!)
            show(replaceOwnerReviewVC, sender: self)
        } catch {
            LogService.shared.info("[REPLACE_OWNER] failed")
        }

    }

}
