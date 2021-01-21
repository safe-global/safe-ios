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

    private var safe: Safe!
    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        do {
            safe = try Safe.getSelected()!
            titleLabel.setStyle(.body)
            importOwnerKeyButton.setText("Import owner key", .filled)
            skipButton.setText("Skip", .plain)
            safeInfoView.set(safe.name)
            safeInfoView.setAddress(safe.addressValue, label: nil)
        } catch {
            fatalError()
        }
    }

    @IBAction func importOwnerButtonTouched(_ sender: Any) {
        Tracker.shared.track(event: TrackingEvent.userOnboardingOwnerImport)
        let vc = ViewControllerFactory.importOwnerViewController(presenter: self)
        present(vc, animated: true)
    }

    @IBAction func skipButtonTouched(_ sender: Any) {
        Tracker.shared.track(event: TrackingEvent.userOnboardingOwnerSkip)
        completion()
    }
}
