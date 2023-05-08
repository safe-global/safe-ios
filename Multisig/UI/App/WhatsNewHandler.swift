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
//        let whatsNew = WhatsNew(
//            version: "3.19.0",
//            title: "What's new",
//            features: [
//                WhatsNew.Feature(
//                    image: WhatsNew.Feature.Image(name: "ico-whats-new-relayer", bundle: .main, renderingMode: .original, foregroundColor: nil),
//                    title: "Gasless transactions",
//                    subtitle: "Transact without paying gas. Safes on Gnosis Chain receive 5 free transactions per hour for a limited time. Try it out on Gnosis Chain!"
//                ),
//                WhatsNew.Feature(
//                    image: WhatsNew.Feature.Image(name: "ico-whats-new-wc2", bundle: .main, renderingMode: .original, foregroundColor: nil),
//                    title: "WalletConnect V2.0",
//                    subtitle: "Support for WalletConnect V2.0 for easier wallet connection."
//                )
//            ],
//            primaryAction: WhatsNew.PrimaryAction(
//                title: "Let's go",
//                backgroundColor: .primary,
//                foregroundColor: .backgroundPrimary,
//                hapticFeedback: .notification(.success),
//                onDismiss: nil
//            ),
//            secondaryAction: nil
//        )
//
//        // for debugging, use the In-memory store version
//        let versionStore: WhatsNewVersionStore = UserDefaultsWhatsNewVersionStore()
////         let versionStore: WhatsNewVersionStore = InMemoryWhatsNewVersionStore()
//
//        let layout = WhatsNew.Layout(featureImageWidth: 60, featureHorizontalAlignment: .top)
//
//        whatsNewViewController = WhatsNewViewController(
//            whatsNew: whatsNew,
//            versionStore: versionStore,
//            layout: layout
//        )
    }
}
