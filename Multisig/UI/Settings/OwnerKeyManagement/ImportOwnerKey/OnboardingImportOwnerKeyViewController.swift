//
//  OnboardingImportOwnerKeyViewController.swift
//  Multisig
//
//  Created by Moaaz on 1/21/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingImportOwnerKeyViewController: AddKeyOnboardingViewController {
    convenience init(completion: @escaping () -> Void) {
        self.init(
            cards: [
                .init(image: UIImage(named: "ico-onbaording-import-key-1"),
                      title: "How does it work?",
                      body: "Enter the private key or seed phrase of your owner key controlling your Safe. Your owner key will be imported into this app. You can then confirm proposed transactions on the go."),

                .init(image: UIImage(named: "ico-onbaording-import-key-2"),
                      title: "How secure is that?",
                      body: "We only store your private key. We do not store your seed phrase in the app.",
                      link: .init(title: "How is a private key stored on mobile?", url: URL(string: "https://help.gnosis-safe.io/en/articles/4866738-how-are-private-keys-stored-on-gnosis-safe-mobile")!)),

                .init(image: UIImage(named: "ico-onbaording-import-key-3"),
                      title: "Is my wallet supported?",
                      body: "You can use your seed phrase from MetaMask or hardware wallet. We support private keys from any wallet in a hexadecimal 64 characters format. Importing the key will not show the balance for Ether or other assets from your MetaMask or hardware wallet.")],
            viewTrackingEvent: .importOwnerOnboarding,
            completion: completion
        )
        navigationItem.title = "Import Owner Key"
    }

    @objc override func didTapNextButton(_ sender: Any) {
        let controller = EnterKeyOrSeedPhraseViewController(completion: completion)
        show(controller, sender: self)
    }
}
