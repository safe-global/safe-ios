//
//  SafeLoadedViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeLoadedViewController: AccountActionCompletedViewController {

    private var safe: Safe!

    convenience init() {
        self.init(namedClass: AccountActionCompletedViewController.self)
    }

    override func viewDidLoad() {
        do {
            safe = try Safe.getSelected()!
            descriptionText = "\((safe.name ?? "Safe")) is read-only. Would you like to add owner key for this Safe to confirm transactions?"
            accountName = safe.name
            accountAddress = safe.addressValue
            prefix = safe.chain?.shortName
        } catch {
            fatalError()
        }
        titleText = "Load Gnosis Safe"
        headerText = "Safe loaded"
        primaryActionName = "Add owner key"
        secondaryActionName = "Skip"

        super.viewDidLoad()
    }

    override func primaryAction(_ sender: Any) {
        Tracker.trackEvent(.userOnboardingOwnerAdd)
        let vc = ViewControllerFactory.addOwnerViewController { [unowned self] in
            self.dismiss(animated: true) {
                self.completion()
            }
        }
        present(vc, animated: true)
    }

    override func secondaryAction(_ sender: Any) {
        Tracker.trackEvent(.userOnboardingOwnerSkip)
        completion()
    }
}
