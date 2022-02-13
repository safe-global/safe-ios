//
//  ActionPanelView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ActionPanelView: UINibView {
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var rejectButton: UIButton!

    var onConfirm: () -> Void = { }
    var onReject: () -> Void = { }

    override func commonInit() {
        super.commonInit()
        confirmButton.setText("Confirm", .filled)
        rejectButton.setText("Reject", .filledError)
    }

    func setConfirmEnabled(_ enabled: Bool) {
        confirmButton.isEnabled = enabled
    }

    func setRejectEnabled(_ enabled: Bool) {
        rejectButton.isEnabled = enabled
    }

    func setEnabled(_ enabled: Bool) {
        setConfirmEnabled(enabled)
        setRejectEnabled(enabled)
    }

    @IBAction func didTapReject(_ sender: Any) {
        onReject()
    }

    @IBAction func didTapConfirm(_ sender: Any) {
        onConfirm()
    }
}
