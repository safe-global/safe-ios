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

        discussItemLabel.hyperLinkLabel("Discuss SafeDAO improvements - post topics and discuss in our",
                prefixStyle: .secondary,
                linkText: "Forum",
                linkIcon: nil,
                underlined: false
        )
        openUrlOnTap(link: .discuss, label: discussItemLabel)

        proposeItemLabel.hyperLinkLabel("Propose improvements - read our governance ",
                prefixStyle: .secondary,
                linkText: "process",
                linkIcon: nil,
                underlined: false,
                postfixText: " and post an SIP."
        )
        openUrlOnTap(link: .propose, label: proposeItemLabel)

        let governText = "Govern improvements - vote on our Snapshot."
        governItemLabel.setStyle(.secondary)

        chatItemLabel.setStyle(.secondary)
        chatItemLabel.hyperLinkLabel("Chat with the community - join our Safe ",
                prefixStyle: .secondary,
                linkText: "Discord.",
                linkIcon: nil,
                underlined: false
        )
        openUrlOnTap(link: .chat, label: chatItemLabel)

        subTitle.setStyle(.headline)
        subTitle.textAlignment = .center
    }

    @IBAction func nextClicked(_ sender: Any) {
        Tracker.trackEvent(.userClaimDaoStart)
        completion?()
    }

    func openUrlOnTap(link: link, label: UILabel) {
        var tapRecognizer: UITapGestureRecognizer
        switch link {
        case .discuss: tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(discussTap(sender:)))
        case .propose: tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(proposeTap(sender:)))
        case .chat:  tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(chatTap(sender:)))
        }
        label.addGestureRecognizer(tapRecognizer)
    }

    @objc
    func discussTap(sender: UITapGestureRecognizer) {
        guard let url = URL(string: "https://forum.gnosis-safe.io/") else {
            return
        }
        openInSafari(url)
    }

    @objc
    func proposeTap(sender: UITapGestureRecognizer) {
        guard let url = URL(string: "https://docs.google.com/document/d/1t79exFjYZQO80yDc8X2S61d4Sc1_QjBwnzZgTSWqoUo/edit#heading=h.ao7vqnfg6hyh") else {
            return
        }
        openInSafari(url)
    }

    @objc
    func chatTap(sender: UITapGestureRecognizer) {
        guard let url = URL(string: "https://discord.com/invite/AjG7AQD9Qn") else {
            return
        }
        openInSafari(url)
    }

    enum link {
        case discuss, propose, chat
    }
}

