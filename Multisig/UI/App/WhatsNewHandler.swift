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
        let whatsNew = WhatsNew(
            version: "3.18.0",
            title: "What's new",
            features: [
                WhatsNew.Feature(
                    image: WhatsNew.Feature.Image(name: "ico-whats-new-rebrand", bundle: .main, renderingMode: .original, foregroundColor: nil),
                    title: "New look! ✨",
                    subtitle: "Safe is following up with a new look. We have updated the color palette in the app, including dark mode."
                ),
                WhatsNew.Feature(
                    image: WhatsNew.Feature.Image(name: "ico-whats-new-collectible", bundle: .main, renderingMode: .original, foregroundColor: nil),
                    title: "Collectibles are back 💥",
                    subtitle: "Now you can view collectibles in your Safe. Access it from the Assets tab - Collectibles."
                ),
                WhatsNew.Feature(
                    image: WhatsNew.Feature.Image(name: "ico-whats-new-keystone", bundle: .main, renderingMode: .original, foregroundColor: nil),
                    title: "Keystone support 🗝",
                    subtitle: "We have partnered with Keystone to support the user-friendly hardware wallet in the app natively. Connect it from Settings - Owner Keys - Add."
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
//        let versionStore: WhatsNewVersionStore = UserDefaultsWhatsNewVersionStore()
         let versionStore: WhatsNewVersionStore = InMemoryWhatsNewVersionStore()

        let layout = WhatsNew.Layout(featureImageWidth: 60, featureHorizontalAlignment: .top)

        whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew,
            versionStore: versionStore,
            layout: layout
        )
    }
}
