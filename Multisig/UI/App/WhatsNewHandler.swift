//
// Created by Dirk Jäckel on 22.12.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WhatsNewKit

class WhatsNewHandler {
    private let whatsNew = WhatsNew(
            // Show the WhatsNew screen only once for users of this version
            version: WhatsNew.Version(major: 3, minor: 8, patch: 0),
            title: "What's new",
            items: [
                WhatsNew.Item(
                        title: "Create a new Safe",
                        subtitle: "Get full control over your Safes and create new ones wherever you are by using owner keys.",
                        image: UIImage(named: "ico-whats-new-safe")
                ),
                WhatsNew.Item(
                        title: "Connect keys to Web",
                        subtitle: "Connect your owner keys to the Web version to sign transactions with your mobile device.",
                        image: UIImage(named: "ico-whats-new-connect")
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
                    versionStore: InMemoryWhatsNewVersionStore() // use InMemoryWhatsNewVersionStore() for debugging
            )
        }
    }
}
