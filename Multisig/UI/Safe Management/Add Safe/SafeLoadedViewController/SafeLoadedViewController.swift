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
    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        navigationItem.title = "Load Safe Multisig"
        do {
            safe = try Safe.getSelected()!
            titleLabel.setStyle(.headline)
            descriptionLabel.setStyle(.body)
            importOwnerKeyButton.setText("Import owner key", .filled)
            let buttonFont = UIFont.gnoFont(forTextStyle: .body)
            skipButton.setText("Skip", GNOButtonStyle.plain.font(buttonFont))
            safeInfoView.set(safe.name)
            safeInfoView.setAddress(safe.addressValue, label: nil)
        } catch {
            fatalError()
        }
    }

    @IBAction func importOwnerButtonTouched(_ sender: Any) {
        Tracker.shared.track(event: TrackingEvent.userOnboardingOwnerImport)
        // Add show enter seedphase screen
    }

    @IBAction func skipButtonTouched(_ sender: Any) {
        Tracker.shared.track(event: TrackingEvent.userOnboardingOwnerSkip)
        completion()
    }
}
