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
    @IBOutlet private weak var par1Label: UILabel!
    @IBOutlet private weak var par2Label: UILabel!
    @IBOutlet private weak var par3Label: UILabel!
    @IBOutlet private weak var par4Label: UILabel!
    @IBOutlet private weak var nextButton: UIButton!

    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.removeNavigationBarBorder(self)

        titleLabel.setStyle(.title1)

        par1Label.setStyle(.subheadlineSecondary)
        let relayerSymbol = NSTextAttachment()
        relayerSymbol.image = UIImage(named: "ico-relayer-symbol")
        let relayerSymbolString = NSMutableAttributedString(attachment: relayerSymbol)
        relayerSymbolString.append(
            NSAttributedString(
                string: "\u{00a0}Relayer\u{00a0}V1",
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor.labelPrimary,
                    NSAttributedString.Key.font: UIFont.gnoFont(forTextStyle: GNOTextStyle.headlinePrimary)
                ]
            )
        )
        let sec1Par1String = NSMutableAttributedString(string: "Tired of handling gas limits? We’ve heard you! Pay for your gasless transactions with our ")
        sec1Par1String.append(relayerSymbolString)
        sec1Par1String.append(NSAttributedString(string: " service with your Safe Account balance."))
        par1Label.attributedText = sec1Par1String

        par2Label.setStyle(.subheadlineSecondary)

        par3Label.setStyle(.subheadlineSecondary)

        par4Label.setStyle(.subheadlineSecondary)

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
