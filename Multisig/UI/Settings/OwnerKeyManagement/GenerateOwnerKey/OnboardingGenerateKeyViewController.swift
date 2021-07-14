//
//  OnboardingGenerateKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingGenerateKeyViewController: UITableViewController {
    private var completion: () -> Void = { }

    private var nextButton: UIBarButtonItem!

    private lazy var mnemonic: String = {
        // 16 bit = 12 words
        let seed = Data.randomBytes(length: 16)!
        return BIP39.generateMnemonicsFromEntropy(entropy: seed)!
    }()

    private lazy var privateKey: PrivateKey = {
        try! PrivateKey(mnemonic: mnemonic, pathIndex: 0)
    }()

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

    convenience init(completion: @escaping () -> Void) {
        self.init()
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Create Owner Key"
        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        navigationItem.rightBarButtonItem = nextButton

        tableView.registerCell(CardTableViewCell.self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.generateOwnerOnboarding)
    }

    @objc private func didTapNextButton(_ sender: Any) {
        let vc = EnterAddressNameViewController()
        vc.actionTitle = "Save"
        vc.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        vc.screenTitle = "Enter Key Name"
        vc.trackingEvent = .enterKeyName
        vc.placeholder = "Enter name"
        vc.address = privateKey.address
        vc.completion = { [unowned self, unowned vc] name in
            guard OwnerKeyController.importKey(privateKey, name: name, isDrivedFromSeedPhrase: true),
                  let keyInfo = try? KeyInfo.keys(addresses: [privateKey.address]).first else {
                return
            }

            let message = "The key successfully created. Add it to a Safe on desktop and then restart the mobile app."

            let passcodeCompletion = { [unowned self, unowned vc] in
                App.shared.snackbar.show(message: message)
                let detailsVC = OwnerKeyDetailsViewController(keyInfo: keyInfo, completion: self.completion)
                vc.show(detailsVC, sender: vc)
            }

            if App.shared.auth.isPasscodeSet {
                passcodeCompletion()
            } else {
                let createPasscodeViewController = CreatePasscodeViewController(passcodeCompletion)
                createPasscodeViewController.navigationItem.hidesBackButton = true
                createPasscodeViewController.hidesHeadline = false
                vc.show(createPasscodeViewController, sender: vc)
            }

            AppSettings.hasShownImportKeyOnboarding = true
        }

        show(vc, sender: self)
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
