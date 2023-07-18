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
        whatsNewViewController = nil
        // TODO: Uncomment and change on new releases
        let whatsNew = WhatsNew(
            version: "3.21.0",
            title: "What's new",
            features: [
                WhatsNew.Feature(
                    image: WhatsNew.Feature.Image(name: "ico-whats-new-social-login", bundle: .main, renderingMode: .original, foregroundColor: nil),
                    title: "Seedless login and easy Safe creation on Gnosis Chain",
                    subtitle: "Add description"
                ),
                WhatsNew.Feature(
                    image: WhatsNew.Feature.Image(name: "ico-whats-new-onramp", bundle: .main, renderingMode: .original, foregroundColor: nil),
                    title: "Buy crypto and top up your account",
                    subtitle: "Add description"
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
        // let versionStore: WhatsNewVersionStore = InMemoryWhatsNewVersionStore()
        let versionStore: WhatsNewVersionStore = UserDefaultsWhatsNewVersionStore()

        let layout = WhatsNew.Layout(featureImageWidth: 60, featureHorizontalAlignment: .top)

        whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew,
            versionStore: versionStore,
            layout: layout
        )
    }
}
