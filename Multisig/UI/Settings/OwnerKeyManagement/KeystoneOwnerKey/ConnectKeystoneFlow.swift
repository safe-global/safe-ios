//
//  ConnectKeystoneFlow.swift
//  Multisig
//
//  Created by Zhiying Fan on 15/8/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

final class ConnectKeystoneFlow: AddKeyFlow {
    var flowFactory: ConnectKeystoneFactory {
        factory as! ConnectKeystoneFactory
    }
    
    init(completion: @escaping (Bool) -> Void) {
        super.init(badge: KeyType.keystone.imageName, factory: ConnectKeystoneFactory(), completion: completion)
    }
}

final class ConnectKeystoneFactory: AddKeyFlowFactory {
    override func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = super.intro(completion: completion)
        introVC.cards = [
            .init(image: UIImage(named: "ico-onboarding-keystone-device"),
                  title: "How does it work?",
                  body: "Connect your Keystone device and select a key. If it is an owner of your Safe you can sign transactions."),

                .init(image: UIImage(named: "ico-onboarding-keystone-qrcode"),
                      title: "Secured QR codes",
                      body: "Sign anywhere without USB cables or unstable bluetooth via secured and verifiable QR codes."),

                .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                      title: "How secure is that?",
                      body: "Your key will remain on your Keystone wallet. We do not store it in the app.")]
        introVC.viewTrackingEvent = .keystoneOwnerOnboarding
        introVC.navigationItem.title = "Connect Keystone"
        return introVC
    }
}
