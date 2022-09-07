//
//  NavigatingDAOViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 06.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class NavigatingDAOViewController: UIViewController {

    @IBOutlet weak var introductionParagraph: UILabel!
    @IBOutlet weak var screenTitle: UILabel!
    @IBOutlet weak var checklistTitle: UILabel!
    @IBOutlet weak var nextButton: UIButton!

    @IBOutlet weak var discussItemLabel: UILabel!
    @IBOutlet weak var proposeItemLabel: UILabel!
    @IBOutlet weak var governItemLabel: UILabel!
    @IBOutlet weak var chatItemLabel: UILabel!
    @IBOutlet weak var subTitle: UILabel!

    private var onNext: (() -> ())?
    private var completion: (() -> Void)?

    convenience init(completion: @escaping () -> ()) {
        self.init(namedClass: NavigatingDAOViewController.self)
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimDao)

        ViewControllerFactory.removeNavigationBarBorder(self)
        navigationItem.largeTitleDisplayMode = .never
        
        screenTitle.text = "Navigating SafeDAO"
        screenTitle.setStyle(.claimTitle)

        introductionParagraph.setStyle(.secondary)
        introductionParagraph.text = "SafeDAO aims to foster a vibrant ecosystem of applications and wallets leveraging Safe smart contract accounts. This will be achieved through data-backed discussions, grants, ecosystem investments, as well as providing developer tools and infrastructure."

        checklistTitle.text = "How to get involved:"
        checklistTitle.setStyle(.title5)

        nextButton.setText("Start claiming", .filled)

        discussItemLabel.text = "Discuss SafeDAO improvements - post topics and discuss in our forum."
        discussItemLabel.setStyle(.secondary)

        proposeItemLabel.text = "Propose improvements - read our governance process and post an SIP."
        proposeItemLabel.setStyle(.secondary)

        governItemLabel.text = "Govern improvements - vote on our Snapshot."
        governItemLabel.setStyle(.secondary)

        chatItemLabel.text = "Chat with the community - join our Safe Discord."
        chatItemLabel.setStyle(.secondary)

        subTitle.text = "Now help decide on the future of ownership with $SAFE."
        subTitle.setStyle(.headline)
        subTitle.textAlignment = .center
    }

    @IBAction func nextClicked(_ sender: Any) {
        Tracker.trackEvent(.userClaimDaoStart)
        completion?()
    }

}
