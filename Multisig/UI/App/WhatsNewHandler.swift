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
            version: "3.17.0",
            title: "What's new",
            features: [
                WhatsNew.Feature(
                    image: WhatsNew.Feature.Image(name: "ico-whats-new-airdrop", bundle: .main, renderingMode: .original, foregroundColor: nil),
                    title: "The SAFE Airdrop!",
                    subtitle: "Check if your Safe is eligible for the SAFE airdrop and claim the tokens in the app."
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
//         let versionStore: WhatsNewVersionStore = InMemoryWhatsNewVersionStore()

        let layout = WhatsNew.Layout(featureImageWidth: 60, featureHorizontalAlignment: .top)

        whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew,
            versionStore: versionStore,
            layout: layout
        )
    }
}
