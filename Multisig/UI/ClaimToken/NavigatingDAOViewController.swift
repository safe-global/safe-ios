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

        discussItemLabel.setStyle(.secondary)
        proposeItemLabel.setStyle(.secondary)
        governItemLabel.setStyle(.secondary)
        chatItemLabel.setStyle(.secondary)

        subTitle.setStyle(.headline)
        subTitle.textAlignment = .center
    }

    @IBAction func nextClicked(_ sender: Any) {
        Tracker.trackEvent(.userClaimDaoStart)
        completion?()
    }

}
