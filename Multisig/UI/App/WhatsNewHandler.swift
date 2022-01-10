//
// Created by Dirk Jäckel on 22.12.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WhatsNewKit

class WhatsNewHandler {
    private let whatsNew = WhatsNew(
            // Show the WhatsNew screen only once for users of this version
            version: WhatsNew.Version(major: 3, minor: 6, patch: 0),
            title: "What's new",
            items: [
                WhatsNew.Item(
                        title: "Intercom chat support",
                        subtitle: "Have a trouble or want to leave feedback? Drop us a message directly in the Intercom chat.",
                        image: UIImage(named: "ico-whats-new-chat")
                ),
                WhatsNew.Item(
                        title: "Initiate asset transfer",
                        subtitle: "Initiate a transfer of your tokens on-the-go...",
                        image: UIImage(named: "ico-whats-new-ether")
                ),
                WhatsNew.Item(
                        title: "Execute transactions",
                        subtitle: "...and execute those transactions from your mobile.",
                        image: UIImage(named: "ico-whats-new-transactions")
                )
            ]
    )

    var whatsNewViewController: WhatsNewViewController?

    init() {
        let whatsNews = [whatsNew]
        var configuration = WhatsNewViewController.Configuration()

        configuration.backgroundColor = .quaternaryBackground

        configuration.titleView.titleColor = .primaryLabel
        configuration.titleView.titleFont = .systemFont(ofSize: 26, weight: .regular)

        configuration.itemsView.titleFont = .systemFont(ofSize: 16, weight: .bold)
        configuration.itemsView.titleColor = .primaryLabel
        configuration.itemsView.subtitleColor = .secondaryLabel

        configuration.detailButton?.titleColor = .button
        configuration.completionButton.backgroundColor = .button
        configuration.completionButton.title = "Let's go"

        configuration.itemsView.autoTintImage = false

        let keyValueVersionStore = KeyValueWhatsNewVersionStore(
                keyValueable: UserDefaults.standard
        )

        let whatsNewForCurrentVersion = whatsNews.get(byVersion: .current())
        if let whatsNewForCurrentVersion = whatsNewForCurrentVersion {
            whatsNewViewController = WhatsNewViewController(
                    whatsNew: whatsNewForCurrentVersion,
                    configuration: configuration,
                    versionStore: keyValueVersionStore // use InMemoryWhatsNewVersionStore() for debugging
            )
        }
    }
}
