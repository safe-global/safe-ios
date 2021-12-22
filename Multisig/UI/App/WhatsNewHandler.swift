//
// Created by Dirk Jäckel on 22.12.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import WhatsNewKit

class WhatsNewHandler {
    let whatsNew = WhatsNew(
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

        var configuration = WhatsNewViewController.Configuration()

        configuration.backgroundColor = .white

        configuration.titleView.titleColor = .darkText

        configuration.itemsView.titleFont = .systemFont(ofSize: 17, weight: .bold)
        configuration.itemsView.titleColor = .darkText

        configuration.detailButton?.titleColor = .button
        configuration.completionButton.backgroundColor = .button
        configuration.completionButton.title = "Let's go"

        let keyValueVersionStore = KeyValueWhatsNewVersionStore(
                keyValueable: UserDefaults.standard
        )

        whatsNewViewController = WhatsNewViewController(
                whatsNew: whatsNew,
                configuration: configuration,
                versionStore: InMemoryWhatsNewVersionStore() // keyValueVersionStore // persist
        )
    }

    func getViewController() -> WhatsNewViewController? {
        whatsNewViewController
    }
}