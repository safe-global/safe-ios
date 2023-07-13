//
//  SocialLoginInfoViewController.swift
//  Multisig
//
//  Created by Vitaly on 12.07.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class SocialLoginInfoViewController: UIViewController {

    @IBOutlet weak var sec1Label: UILabel!
    @IBOutlet weak var sec2TitleLabel: UILabel!
    @IBOutlet weak var sec2Label: UILabel!
    @IBOutlet weak var readMoreLabel: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(CloseModal.closeModal))
        title = "How does it work?"

        sec1Label.setStyle(.subheadlineSecondary)
        let sec1Par1String = "Your Google or Apple ID will serve as the 1/1 owner of your new Safe Account.   For enhanced security, you can always add more owners later.".highlightRange(
            originalStyle: .subheadlineSecondary,
            highlightStyle: .subheadlineSecondary.color(.labelPrimary),
            textToHighlight: "1/1 owner")
        sec1Par1String.paragraph()
        sec1Label.attributedText = sec1Par1String

        sec2TitleLabel.setStyle(.headline)

        sec2Label.setStyle(.subheadlineSecondary)

        readMoreLabel.hyperLinkLabel(linkText: "Read more in Help Center", underlined: false)
    }

    @IBAction func didTapReadMore(_ sender: Any) {
        openInSafari(App.configuration.help.socialLoginInfoURL)
    }
}
