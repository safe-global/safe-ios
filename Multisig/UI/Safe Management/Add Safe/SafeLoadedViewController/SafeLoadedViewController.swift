//
//  SafeLoadedViewController.swift
//  Multisig
//
//  Created by Moaaz on 1/19/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeLoadedViewController: UIViewController {
    @IBOutlet weak var safeInfoView: SafeInfoViewV2!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var importOwnerKeyButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!

    private var safe: Safe!
    private let descriptionText = " is read-only. Would you like to import owner key for this Safe to confirm transactions?"
    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        navigationItem.title = "Load Safe Multisig"
        do {
            safe = try Safe.getSelected()!
            descriptionLabel.text = (safe.name ?? "Safe") + descriptionText
            titleLabel.setStyle(.headline)
            descriptionLabel.setStyle(.primary)
            importOwnerKeyButton.setText("Import owner key", .filled)
            skipButton.setText("Skip", .primary)
            safeInfoView.set(safe.name)
            safeInfoView.setAddress(safe.addressValue)
        } catch {
            fatalError()
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(ownerKeyImported), name: .ownerKeyImported, object: nil)
    }

    @IBAction func importOwnerButtonTouched(_ sender: Any) {
        Tracker.shared.track(event: TrackingEvent.userOnboardingOwnerImport)
        let vc = ViewControllerFactory.selectKeyTypeViewController(presenter: self)
        present(vc, animated: true)
    }

    @IBAction func skipButtonTouched(_ sender: Any) {
        Tracker.shared.track(event: TrackingEvent.userOnboardingOwnerSkip)
        completion()
    }

    @objc private func ownerKeyImported() {
        completion()
    }
}
