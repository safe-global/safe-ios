//
//  SuggestToAddSignerViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SuggestToAddSignerViewController: AccountActionCompletedViewController {

    var onAddSigner: (() -> Void)!
    private var safe: Safe!

    convenience init() {
        self.init(namedClass: AccountActionCompletedViewController.self)
    }

    override func viewDidLoad() {
        do {
            safe = try Safe.getSelected()!
            descriptionText = "\((safe.name ?? "Safe Account")) is read-only. Would you like to add owner key for this Safe Account to confirm transactions?"
            accountName = safe.name
            accountAddress = safe.addressValue
            prefix = safe.chain?.shortName
        } catch {
            fatalError()
        }
        titleText = "Load Safe Account"
        headerText = "Safe Account loaded"
        primaryActionName = "Add owner key"
        secondaryActionName = "Skip"

        super.viewDidLoad()
    }

    override func primaryAction(_ sender: Any) {
        Tracker.trackEvent(.userOnboardingOwnerAdd)
        onAddSigner?()
    }

    override func secondaryAction(_ sender: Any) {
        Tracker.trackEvent(.userOnboardingOwnerSkip)
        completion()
    }
}
