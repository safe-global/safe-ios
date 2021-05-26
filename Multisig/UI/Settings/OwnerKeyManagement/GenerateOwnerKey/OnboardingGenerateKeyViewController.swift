//
//  OnboardingGenerateKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingGenerateKeyViewController: UITableViewController {
    private var nextButton: UIBarButtonItem!

    private let cards: [(image: UIImage?, title: String, body: String, link: (title: String?, url: URL?))] = [
        (UIImage(named: "ico-onbaording-import-key-1"),
         "How does it work?",
         "To use this app as an owner in the Gnosis Safe, you can create a key and add it as an owner of your Safe. When you tap Next, the app will create a new private key from a new unique seed phrase.",
         (nil, nil)),

        (UIImage(named: "ico-onbaording-import-key-2"),
         "How secure is that?",
         "The owner key and the seed phrase are stored in the device's secure store - iOS Keychain.",
         ("How is a private key stored on mobile?", URL(string: "https://help.gnosis-safe.io/en/articles/4866738-how-are-private-keys-stored-on-gnosis-safe-mobile"))),

        (UIImage(named: "ico-onbaording-import-key-3"),
         "How to export?",
         "To export your owner key or seed phrase, navigate to the key details.",
         (nil, nil))
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Create Owner Key"
        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        navigationItem.rightBarButtonItem = nextButton

        tableView.registerCell(CardTableViewCell.self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.generateOwnerOnboarding)
    }

    @objc private func didTapNextButton(_ sender: Any) {        
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cards.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(CardTableViewCell.self, for: indexPath)
        let card = cards[indexPath.row]
        cell.set(image: card.0)
        cell.set(title: card.1)
        cell.set(body: card.2)
        cell.set(linkTitle: card.3.0, url: card.3.1)

        return cell
    }
}
