//
//  GuardianDetailsViewController.swift
//  Multisig
//
//  Created by Vitaly on 27.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class GuardianDetailsViewController: UIViewController {

    @IBOutlet weak var identiconInfoView: IdenticonInfoView!
    @IBOutlet weak var viewOnEtherscan: HyperlinkButtonView!
    @IBOutlet weak var reasonTitleLabel: UILabel!
    @IBOutlet weak var reasonTextLabel: UILabel!
    @IBOutlet weak var contributionTitleLabel: UILabel!
    @IBOutlet weak var contributionTextLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!

    var chain: Chain! = Chain.mainnetChain()
    var guardian: Guardian!
    var onSelected: ((Guardian) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimDeldet)

        ViewControllerFactory.removeNavigationBarBorder(self)
        title = "Choose a delegate"
        navigationItem.largeTitleDisplayMode = .never

        identiconInfoView.setGuardian(guardian: guardian)

        viewOnEtherscan.setText("View on Etherscan", underlined: false)

        reasonTitleLabel.setStyle(.headline)
        reasonTextLabel.setStyle(.body)
        reasonTextLabel.text = guardian.reason

        contributionTitleLabel.setStyle(.headline)
        contributionTextLabel.setStyle(.body)
        contributionTextLabel.text = guardian.contribution

        continueButton.setText("Select & Continue", .filled)

        if guardian.address.address == Address.zero {
            App.shared.snackbar.show(message: "Missing ENS name or guardian address")
            continueButton.isEnabled = false
        } else {
            viewOnEtherscan.url = chain.browserURL(address: guardian.address.address.checksummed)
        }

        let reasonTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        reasonTextLabel.addGestureRecognizer(reasonTapRecognizer)
        reasonTextLabel.isUserInteractionEnabled = true

        let contributionTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        contributionTextLabel.addGestureRecognizer(contributionTapRecognizer)
        contributionTextLabel.isUserInteractionEnabled = true
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard sender.state == .ended, let view = sender.view as? UILabel, view == reasonTextLabel || view == contributionTextLabel, let text = view.text, !text.isEmpty else {
            return
        }

        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: text, range: NSRange(location: 0, length: text.count))
            if let match = matches.first, let url = match.url {
                openInSafari(url)
                return
            }
        } catch {
            // ignore but log error
            LogService.shared.error("Can't detect text data types: \(error)")
        }

        // if all fails, just copy on tap
        Pasteboard.string = text
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    @IBAction func didTapContinueButton(_ sender: Any) {
        Tracker.trackEvent(.userClaimDeldetSelect)
        onSelected?(guardian)
    }
}
