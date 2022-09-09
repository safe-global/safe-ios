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
        
        screenTitle.setStyle(.claimTitle)

        introductionParagraph.setStyle(.secondary)

        checklistTitle.setStyle(.title5)

        nextButton.setText("Start claiming", .filled)
        let discussText = "Discuss SafeDAO improvements - post topics and discuss in our"
        discussItemLabel.hyperLinkLabel(discussText, prefixStyle: .secondary, linkText: "Forum", linkIcon: nil, underlined: false)
        let discussTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(discussTap(sender:)))
        discussItemLabel.addGestureRecognizer(discussTapRecognizer)
        discussItemLabel.isUserInteractionEnabled = true

        let proposeText = "Propose improvements - read our governance process and post an SIP."
        proposeItemLabel.hyperLinkLabel(proposeText, prefixStyle: .secondary, linkText: "process", linkIcon: nil, underlined: false)
        discussItemLabel.addGestureRecognizer(discussTapRecognizer)
        discussItemLabel.isUserInteractionEnabled = true

        let governText = ""
        governItemLabel.setStyle(.secondary)
        let chatText = ""
        chatItemLabel.setStyle(.secondary)

        subTitle.setStyle(.headline)
        subTitle.textAlignment = .center
    }

    @IBAction func nextClicked(_ sender: Any) {
        Tracker.trackEvent(.userClaimDaoStart)
        completion?()
    }

    @objc
    func discussTap(sender: UITapGestureRecognizer) {
        guard let url = URL(string: "https://forum.gnosis-safe.io/") else {
            fatalError("guard failure handling has not been implemented")
        }
        openInSafari(url)
    }
}
