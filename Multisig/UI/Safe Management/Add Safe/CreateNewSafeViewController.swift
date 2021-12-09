//
//  CreateNewSafeViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 09.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreateNewSafeViewController: UIViewController, ExternalURLSource {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var desktopLinkLabel: UILabel!
    @IBOutlet weak var stepOneLabel: UILabel!
    @IBOutlet weak var stepTwoLabel: UILabel!
    @IBOutlet weak var stepThreeLabel: UILabel!
    @IBOutlet weak var webArticleLinkLabel: UILabel!
    @IBOutlet weak var desktopAppButton: UIButton!
    @IBOutlet weak var helpArticleButton: UIButton!

    private(set) var url: URL?

    @IBAction func webArticleLinkPressed(_ sender: Any) {
        url = App.configuration.help.createSafeURL
        openExternalURL()
        Tracker.trackEvent(.createSafeHelpArticle)
    }

    @IBAction func desktopAppLinkPressed(_ sender: Any) {
        url = App.configuration.services.webAppURL
        openExternalURL()
        Tracker.trackEvent(.createSafeDesktopApp)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Create new Safe"

        desktopAppButton.setTitle("", for: .normal)
        helpArticleButton.setTitle("", for: .normal)

        headerLabel.setStyle(.headline)
        descriptionLabel.setStyle(.primary)
        desktopLinkLabel.hyperLinkLabel(linkText: "Desktop App")

        stepOneLabel.setStyle(.primary)
        stepTwoLabel.setStyle(.primary)
        stepThreeLabel.setStyle(.primary)

        webArticleLinkLabel.hyperLinkLabel(linkText: "Still need help? Head to our article to read more how to Create a Safe.")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.createSafe)
    }
}
