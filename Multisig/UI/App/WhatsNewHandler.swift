//
// Created by Dirk Jäckel on 22.12.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WhatsNewKit
import SwiftUI

class WhatsNewHandler {
    var whatsNewViewController: WhatsNewViewController?

    init() {
        let title: WhatsNew.Title
        let featureText: WhatsNew.Text

        if #available(iOS 15, *) {
            var titleString = AttributedString("What's new")
            titleString.font = .systemFont(ofSize: 26, weight: .regular)
            titleString.foregroundColor = .labelPrimary
            title = .init(text: WhatsNew.Text(titleString))


            var featureString = AttributedString("Gnosis Safe has rebranded to ‘Safe’ following a successful spin-off from the Gnosis DAO.\n\nNow and over the coming versions, you will see a new look and a better user experience for your ever secure Gnosis Safe.")
            featureString.foregroundColor = .labelSecondary

            featureText = .init(featureString)
            
        } else {
            title = "What's new"
            featureText = "Gnosis Safe has rebranded to ‘Safe’ following a successful spin-off from the Gnosis DAO.\n\nNow and over the coming versions, you will see a new look and a better user experience for your ever secure Gnosis Safe."
        }


        let whatsNew = WhatsNew(
            version: "3.16.0",
            title: title,
            features: [
                WhatsNew.Feature(
                    image: WhatsNew.Feature.Image(name: "ico-whats-new-rebrand", bundle: .main, renderingMode: .original, foregroundColor: nil),
                    title: "Meet the new Safe!",
                    subtitle: featureText
                )
            ],
            primaryAction: WhatsNew.PrimaryAction(
                title: "Let's go",
                backgroundColor: .primary,
                foregroundColor: .backgroundPrimary,
                hapticFeedback: .notification(.success),
                onDismiss: nil
            ),
            secondaryAction: nil
        )

        // for debugging, use the In-memory store version
        let versionStore: WhatsNewVersionStore = UserDefaultsWhatsNewVersionStore()
        // let versionStore: WhatsNewVersionStore = InMemoryWhatsNewVersionStore()

        let layout = WhatsNew.Layout(featureImageWidth: 60, featureHorizontalAlignment: .top)

        whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew,
            versionStore: versionStore,
            layout: layout
        )
    }
}
