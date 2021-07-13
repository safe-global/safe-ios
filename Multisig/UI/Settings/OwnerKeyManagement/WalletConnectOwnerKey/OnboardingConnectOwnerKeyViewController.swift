//
//  OnboardingConnectOwnerKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingConnectOwnerKeyViewController: UITableViewController {
    private var completion: () -> Void = {}

    private var nextButton: UIBarButtonItem!

    private let cards = [
        (UIImage(named: "ico-onbaording-import-key-1"),
         "How does it work?",
         "You can connect an owner key from another wallet. You will be asked to select it from a list of already installed wallets on your phone or you can display a QR code and scan it with another wallet."),

        (UIImage(named: "ico-onbaording-import-key-2"),
         "How secure is that?",
         "WalletConnect is a secure protocol for exchanging messages. Gnosis Safe app will not get access to your private key stored in your wallet."),

        (UIImage(named: "ico-onbaording-import-key-3"),
         "Is my wallet supported?",
         "You wallet needs to support the WalletConnect protocol.")
    ]

    convenience init(completion: @escaping () -> Void) {
        self.init()
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Connect Owner Key"
        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        navigationItem.rightBarButtonItem = nextButton

        tableView.registerCell(CardTableViewCell.self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.connectOwnerOnboarding)
    }

    @objc private func didTapNextButton(_ sender: Any) {
        let controller = ConnectWalletViewController(completion: completion)
        show(controller, sender: self)
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
        cell.set(linkTitle: nil, url: nil)

        return cell
    }
}
