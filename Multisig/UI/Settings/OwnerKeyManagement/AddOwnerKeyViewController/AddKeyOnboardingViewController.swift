//
//  AddKeyOnboardingViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

// base class for onboarding screens when addding a key
class AddKeyOnboardingViewController: UITableViewController {
    struct Card {
        var image: UIImage?
        var title: String
        var body: String
        var link: Link?

        struct Link {
            var title: String
            var url: URL
        }
    }

    var cards: [Card] = []
    private var nextButton: UIBarButtonItem!
    var viewTrackingEvent: TrackingEvent!
    var createPasscodeFlow: CreatePasscodeFlow!

    // set by a controller during some step in the flow
    var keyParameters: AddKeyParameters?

    var completion: () -> Void = { }

    convenience init(cards: [Card], viewTrackingEvent: TrackingEvent, completion: @escaping () -> Void) {
        self.init()
        self.cards = cards
        self.completion = completion
        self.viewTrackingEvent = viewTrackingEvent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        navigationItem.rightBarButtonItem = nextButton

        tableView.registerCell(CardTableViewCell.self)

        tableView.backgroundColor = .backgroundPrimary
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(viewTrackingEvent)
    }

    @objc func didTapNextButton(_ sender: Any) {
        // to override
        completion()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cards.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(CardTableViewCell.self, for: indexPath)
        let card = cards[indexPath.row]
        cell.set(image: card.image)
        cell.set(title: card.title)
        cell.set(body: card.body)
        cell.set(linkTitle: card.link?.title, url: card.link?.url)
        return cell
    }
}
