//
// Created by Dirk Jäckel on 22.12.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WhatsNewKit

class WhatsNewHandler {
    private let whatsNew = WhatsNew(
            // Show the WhatsNew screen only once for users of this version
            version: WhatsNew.Version(major: 3, minor: 16, patch: 0),
            title: "What's new",
            items: [
                WhatsNew.Item(
                        title: "We have changed!",
                        subtitle: "Gnosis Safe rebranded to Safe. Following a successful spin-off vote from Gnosis in GIP-29, we are rebranding to Safe. Now and over the coming time, you will see a new look and a better visual experience to your ever secure Gnosis Safe that you love.",
                        image: UIImage(named: "ico-whats-new-rebrand")
                )
            ]
    )

    var whatsNewViewController: WhatsNewViewController?

    init() {
        let whatsNews = [whatsNew]
        var configuration = WhatsNewViewController.Configuration()

        configuration.backgroundColor = .backgroundSecondary

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
