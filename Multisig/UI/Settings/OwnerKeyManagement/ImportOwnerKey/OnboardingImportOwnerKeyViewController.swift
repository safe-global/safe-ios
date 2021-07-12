//
//  OnboardingImportOwnerKeyViewController.swift
//  Multisig
//
//  Created by Moaaz on 1/21/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingImportOwnerKeyViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var completion: () -> Void = { }

    private var nextButton: UIBarButtonItem!

    private let cards: [(image: UIImage?, title: String, body: String, link: (title: String?, url: URL?))] = [
        (UIImage(named: "ico-onbaording-import-key-1"),
         "How does it work?",
         "Enter the private key or seed phrase of your owner key controlling your Safe. Your owner key will be imported into this app. You can then confirm proposed transactions on the go.",
         (nil, nil)),

        (UIImage(named: "ico-onbaording-import-key-2"),
         "How secure is that?",
         "We only store your private key. We do not store your seed phrase in the app.",
         ("How is a private key stored on mobile?", URL(string: "https://help.gnosis-safe.io/en/articles/4866738-how-are-private-keys-stored-on-gnosis-safe-mobile"))),

        (UIImage(named: "ico-onbaording-import-key-3"),
         "Is my wallet supported?",
         "You can use your seed phrase from MetaMask or hardware wallet. We support private keys from any wallet in a hexadecimal 64 characters format. Importing the key will not show the balance for Ether or other assets from your MetaMask or hardware wallet.",
         (nil, nil))]

    convenience init(completion: @escaping () -> Void) {
        self.init()
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(CardTableViewCell.self)

        navigationItem.title = "Import Owner Key"
        
        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        navigationItem.rightBarButtonItem = nextButton
    }

    @objc private func didTapNextButton(_ sender: Any) {
        let controller = EnterKeyOrSeedPhraseViewController(completion: completion)
        show(controller, sender: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.importOwnerOnboarding)
    }
}


extension OnboardingImportOwnerKeyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(CardTableViewCell.self, for: indexPath)
        let card = cards[indexPath.row]
        cell.set(image: card.0)
        cell.set(title: card.1)
        cell.set(body: card.2)
        cell.set(linkTitle: card.3.0, url: card.3.1)

        return cell
    }
}
