//
// Created by Dirk Jäckel on 22.12.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WhatsNewKit

class WhatsNewHandler {
    private let whatsNew = WhatsNew(
            // Show the WhatsNew screen only once for users of this version
            version: WhatsNew.Version(major: 3, minor: 14, patch: 0),
            title: "What's new",
            items: [
                WhatsNew.Item(
                        title: "Edit Safe Owners",
                        subtitle: "Connect your owner key to the Safe and edit Safe owners and confirmation requirements in the Safe settings.",
                        image: UIImage(named: "ico-whats-new-edit-safe-owners")
                ),
                WhatsNew.Item(
                        title: "Request to join a Safe",
                        subtitle: "After creating new owner key request to join the selected Safe by sharing a link with one of the owners.",
                        image: UIImage(named: "ico-whats-new-join-safe")
                )
            ]
    )

    var whatsNewViewController: WhatsNewViewController?

    init() {
        let whatsNews = [whatsNew]
        var configuration = WhatsNewViewController.Configuration()

        configuration.backgroundColor = .backgroundQuaternary

        configuration.titleView.titleColor = .labelPrimary
        configuration.titleView.titleFont = .systemFont(ofSize: 26, weight: .regular)

        configuration.itemsView.titleFont = .systemFont(ofSize: 16, weight: .bold)
        configuration.itemsView.titleColor = .labelPrimary
        configuration.itemsView.subtitleColor = .labelSecondary

        configuration.detailButton?.titleColor = .primary
        configuration.completionButton.backgroundColor = .primary
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
