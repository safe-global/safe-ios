//
//  LegalDisclaimerViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class LegalDisclaimerViewController: UIViewController {
    @IBOutlet private weak var agreeButton: UIButton!
    @IBOutlet private weak var textLabel: UILabel!

    var onAgree: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimLegal)

        ViewControllerFactory.removeNavigationBarBorder(self)
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.title = "Legal Disclaimer"
        agreeButton.setText("Agree & Continue", .filled)
        let attrString = "This app is for our community to encourage Safe ecosystem contributors and users to unlock SafeDAO governance.\nTHIS APP IS PROVIDED “AS IS” AND “AS AVAILABLE,” AT YOUR OWN RISK, AND WITHOUT WARRANTIES OF ANY KIND.\nWe will not be liable for any loss, whether such loss is direct, indirect, special or consequential, suffered by any party as a result of their use of this app.\nBy accessing this app, you represent and warrant:\n- that you are of legal age and that you will comply with any laws applicable to you and not engage in any illegal activities;\n- that you are claiming Safe tokens to participate in the SafeDAO governance process and that they do not represent consideration for past or future services;\n- that you, the country you are a resident of and your wallet address is not on any sanctions lists maintained by the United Nations, Switzerland, the EU, UK or the US;\n- that you are responsible for any tax obligations arising out of the interaction with this app.\nNone of the information available on this app, or made otherwise available to you in relation to its use, constitutes any legal, tax, financial or other advice. Where in doubt as to the action you should take, please consult your own legal, financial, tax or other professional advisors.".highlightRange(
            originalStyle: .body,
            highlightStyle: .bodyMedium.color(.labelPrimary),
            textToHighlight: "By accessing this app, you represent and warrant:")
        attrString.paragraph()
        textLabel.attributedText = attrString
    }

    @IBAction func didTapAgreeButton(_ sender: Any) {
        Tracker.trackEvent(.userClaimLegalAgree)
        onAgree?()
    }
}
