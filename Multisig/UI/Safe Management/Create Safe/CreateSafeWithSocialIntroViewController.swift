//
//  CreateSafeWithSocialIntroViewController.swift
//  Multisig
//
//  Created by Mouaz on 6/19/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreateSafeWithSocialIntroViewController: UIViewController {
    @IBOutlet private weak var ribbonView: RibbonView!
    @IBOutlet private weak var googleButton: UIButton!
    @IBOutlet private weak var appleButton: UIButton!
    @IBOutlet private weak var addressButton: UIButton!
    @IBOutlet private weak var orLabel: UILabel!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var infoView3: InfoView!
    @IBOutlet private weak var infoView2: InfoView!
    @IBOutlet private weak var infoView1: InfoView!

    var chain: Chain!
    var onAppleAction: () -> () = {}
    var onGoogleAction: () -> () = {}
    var onAddressAction: () -> () = {}

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Create a Safe Account"
        navigationItem.backButtonTitle = "Back"
        ribbonView.update(chain: chain)
        orLabel.setStyle(.caption1)
        appleButton.setText("Continue with Apple ID", .filled)
        googleButton.setText("Continue with Google", .filled)
        addressButton.setText("Continue with a wallet address", .bordered)
        infoView1.set(text: "Create a Safe Account now and add more owners later for better security")
        infoView2.set(text: "Your owner key is secured by your social login only")
        infoView3.set(text: "No need to keep seed phrases")
        headerLabel.hyperLinkLabel("Select a social login to create your Safe Account.",
                                   prefixStyle: .body,
                                   linkText: "How does it work?",
                                   linkStyle: .button,
                                   linkIcon: nil,
                                   underlined: false)
        //FIXME: remove beta label when social login feature not in beta
        headerLabel.apendBetaBadge()
        headerLabel.isUserInteractionEnabled = true
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(didTapHowItWorks(_ :)))
        tapgesture.numberOfTapsRequired = 1
        headerLabel.addGestureRecognizer(tapgesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.screenStartingInfo)
    }

    @IBAction func googleButtonTouched(_ sender: Any) {
        Tracker.trackEvent(.userContinueGoogle)
        onGoogleAction()
    }

    @IBAction func appleButtonTouched(_ sender: Any) {
        Tracker.trackEvent(.userContinueApple)
        onAppleAction()
    }

    @IBAction private func addressButtonTouched(_ sender: Any) {
        Tracker.trackEvent(.userContinueAddress)
        onAddressAction()
    }

    @objc func didTapHowItWorks(_ gesture: UITapGestureRecognizer) {
           guard let text = headerLabel.text else { return }
           let howItWorksRange = (text as NSString).range(of: "How does it work?")
           if gesture.didTapAttributedTextInLabel(label: headerLabel, inRange: howItWorksRange) {
               Tracker.trackEvent(.userHowItWorks)
               let socialLoginInfoVC = SocialLoginInfoViewController()
               show(socialLoginInfoVC, sender: self)
           }
       }
}
