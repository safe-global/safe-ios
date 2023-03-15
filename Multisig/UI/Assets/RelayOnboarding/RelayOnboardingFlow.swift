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
            benefits()
        }
        show(whatIsRelayingVC)
    }

    func benefits() {
        let benefitsVC = factory.benefits { [unowned self] in
            howItWorks()
        }
        show(benefitsVC)
    }

    func howItWorks() {
        let howItWorksVC = factory.howItWorks { [unowned self] in
            uncoverThePower()
        }
        show(howItWorksVC)
    }

    func uncoverThePower() {
        let uncoverThePowerVC = factory.uncoverThePower { [unowned self] in
            stop(success: true)
        }
        show(uncoverThePowerVC)
    }
}

class RelayOnboardingFactory {

    func whatIsRelaying(completion: @escaping () -> Void) -> ROWhatIsViewController {
        let whatIsRelayingVC = ROWhatIsViewController()
        whatIsRelayingVC.completion = completion
        return whatIsRelayingVC
    }

    func benefits(completion: @escaping () -> Void) -> ROBenefitsViewController {
        let benefitsVC = ROBenefitsViewController()
        benefitsVC.completion = completion
        return benefitsVC
    }

    func howItWorks(completion: @escaping () -> Void) -> ROHowItWorksViewController {
        let howItWorksVC = ROHowItWorksViewController()
        howItWorksVC.completion = completion
        return howItWorksVC
    }

    func uncoverThePower(completion: @escaping () -> Void) -> ROUncoverViewController {
        let uncoverThePowerVC = ROUncoverViewController()
        uncoverThePowerVC.completion = completion
        return uncoverThePowerVC
    }
}
