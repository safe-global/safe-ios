//
//  RelayOnboardingFlow.swift
//  Multisig
//
//  Created by Vitaly on 09.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class RelayOnboardingFlow: UIFlow {

    var factory: RelayOnboardingFactory

    override init(completion: @escaping (Bool) -> Void) {
        self.factory = RelayOnboardingFactory()
        super.init(completion: completion)
    }

    override func start() {
        whatIsRelaying()
    }

    func whatIsRelaying() {
        let whatIsRelayingVC = factory.whatIsRelaying { [unowned self] in

        }
        show(whatIsRelayingVC)
    }
}

class RelayOnboardingFactory {

    func whatIsRelaying(completion: @escaping () -> Void) -> ROWhatIsViewController {
        let whatIsRelayingVC = ROWhatIsViewController()
        whatIsRelayingVC.completion = completion
        return whatIsRelayingVC
    }
}
