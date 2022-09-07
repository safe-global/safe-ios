//
//  NavigatingDAOViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 06.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class NavigatingDAOViewController: UIViewController {

    @IBOutlet weak var firstParagraph: UILabel!
    @IBOutlet weak var screenTitle: UILabel!
    @IBOutlet weak var paragraphTitle: UILabel!
    @IBOutlet weak var secondParagraph: UILabel!
    @IBOutlet weak var nextButton: UIButton!

    @IBOutlet weak var item1Label: UILabel!
    @IBOutlet weak var item2Label: UILabel!
    @IBOutlet weak var item3Label: UILabel!
    @IBOutlet weak var item4Label: UILabel!
    @IBOutlet weak var subTitle: UILabel!

    private var onNext: (() -> ())?
    private var completion: (() -> Void)?

    convenience init(completion: @escaping () -> ()) {
        self.init(namedClass: NavigatingDAOViewController.self)
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.removeNavigationBarBorder(self)
        navigationItem.largeTitleDisplayMode = .never
        
        screenTitle.text = "Navigating SafeDAO"
        screenTitle.setStyle(.claimTitle)

        firstParagraph.setStyle(.secondary)
        firstParagraph.text = "SafeDAO aims to foster a vibrant ecosystem of applications and wallets leveraging Safe smart contract accounts. This will be achieved through data-backed discussions, grants, ecosystem investments, as well as providing developer tools and infrastructure."

        paragraphTitle.text = "How to get involved:"
        paragraphTitle.setStyle(.title5)

        secondParagraph.setStyle(.secondary)
        secondParagraph.text = "Lorem Ipsum..."

        nextButton.setText("Start claiming", .filled)

        item1Label.text = "Discuss SafeDAO improvements - post topics and discuss in our forum."
        item1Label.setStyle(.secondary)

        item2Label.text = "Propose improvements - read our governance process and post an SIP."
        item2Label.setStyle(.secondary)

        item3Label.text = "Govern improvements - vote on our Snapshot."
        item3Label.setStyle(.secondary)

        item4Label.text = "Chat with the community - join our Safe Discord."
        item4Label.setStyle(.secondary)

        subTitle.text = "Now help decide on the future of ownership with $SAFE."
        subTitle.setStyle(.headline)
        subTitle.textAlignment = .center
    }

    @IBAction func nextClicked(_ sender: Any) {
        completion?()
    }

}
