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

    override func commonInit() {
        super.commonInit()
        confirmButton.setText("Confirm", .filled)
        rejectButton.setText("Reject", .filledError)
    }
}
