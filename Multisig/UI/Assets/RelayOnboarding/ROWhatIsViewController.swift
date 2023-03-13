//
//  ROWhatIsViewController.swift
//  Multisig
//
//  Created by Vitaly on 09.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class ROWhatIsViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var sec1Par1Label: UILabel!
    @IBOutlet private weak var sec1Par2Label: UILabel!
    @IBOutlet private weak var sec2TitleLabel: UILabel!
    @IBOutlet private weak var sec2Par1Label: UILabel!
    @IBOutlet private weak var moreComingSoonButton: UIButton!
    @IBOutlet private weak var sec3TitleLabel: UILabel!
    @IBOutlet private weak var sec3Par1Label: UILabel!
    @IBOutlet private weak var sec3Par2Label: UILabel!
    @IBOutlet private weak var nextButton: UIButton!

    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.removeNavigationBarBorder(self)

        titleLabel.setStyle(.title1)

        sec1Par1Label.setStyle(.subheadlineSecondary)
        let relayerSymbol = NSTextAttachment()
        relayerSymbol.image = UIImage(named: "ico-relayer-symbol")
        let relayerSymbolString = NSMutableAttributedString(attachment: relayerSymbol)
        relayerSymbolString.append(NSAttributedString(string: "\u{00a0}Relayer\u{00a0}V1", attributes: [NSAttributedString.Key.foregroundColor: UIColor.labelPrimary]))
        let sec1Par1String = NSMutableAttributedString(string: "Tired of handling gas limits? We’ve heard you! Pay for your gasless transactions with our ")
        sec1Par1String.append(relayerSymbolString)
        sec1Par1String.append(NSAttributedString(string: " service with your Safe balance."))
        sec1Par1Label.attributedText = sec1Par1String

        sec1Par2Label.setStyle(.subheadlineSecondary)

        sec2TitleLabel.setStyle(.headline)
        sec2Par1Label.setStyle(.subheadlineSecondary)

        sec3TitleLabel.setStyle(.headline)
        let sec3Par1String = "Our partner Gnosis Chain will temporarily sponsor your transactions via as the first test version. When the full version will be released, it will become a paid service. User can execute any type of transaction.".highlightRange(
            originalStyle: .subheadlineSecondary,
            highlightStyle: .subheadlineSecondary.color(.labelPrimary),
            textToHighlight: "Gnosis Chain")
        sec3Par1String.paragraph()
        sec3Par1Label.attributedText = sec3Par1String

        sec3Par2Label.setStyle(.subheadlineSecondary)

        nextButton.setText("Next", .filled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.relayOnboarding1)
    }

    @IBAction func didTapNext(_ sender: Any) {
        completion()
    }
}
