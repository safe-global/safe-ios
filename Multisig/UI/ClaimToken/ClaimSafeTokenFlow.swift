//
//  ClaimSafeTokenFlow.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter

class ClaimSafeTokenFlow: UIFlow {
    var factory: ClaimSafeTokenFlowFactory!
    var safe: Safe
    var guardian: Guardian!
    var amount: String!

    init(safe: Safe,
         factory: ClaimSafeTokenFlowFactory = ClaimSafeTokenFlowFactory(),
         completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        //TODO remove workaround and check claim availability
        if safe.addressValue == Address(exactly: "0xfF501B324DC6d78dC9F983f140B9211c3EdB4dc7") {
            // if not available show not available
            showNotAvailable()
        } else {
            showIntro()
        }
    }

    func showDisclaimer() {
        let vc = factory.legalDisclaimer {[unowned self] in
            showDelegateIntro()
        }
        show(vc)
    }

    func showNavigatingDAO() {
        let vc = factory.navigatingDAO {[unowned self] in
            showDisclaimer()
        }
        show(vc)
    }


    func showIntro() {
        let vc = factory.claimGetStarted { [unowned self] in
            showWhatIsSafe()
        }
        show(vc)
    }

    func showNotAvailable() {
        let vc = factory.claimNotAvailable()
        show(vc)
    }

    func showDelegateIntro() {
        let vc = factory.chooseDelegateIntro { [unowned self] in
            showGuardian()
        } onCustomAddress: { [unowned self] in
            enterCustomAddress()
        }
        show(vc)
    }

    func showWhatIsSafe() {
        let vc = factory.chooseWhatIsSafe { [unowned self] in
            showNavigatingDAO()
        }
        show(vc)
    }

    func showGuardian() {
        let vc = factory.chooseGuardian() { [unowned self] guardian in
            selectAmount(guardian: guardian)
        }
        show(vc)
    }

    func enterCustomAddress() {
        let vc = factory.enterCustomAddress(mainnet: self.safe.chain?.id == Chain.ChainID.ethereumMainnet) { [unowned self] address in
            let guardian = Guardian(
                name: nil,
                reason: nil,
                contribution: nil,
                address: AddressString(address),
                ens: nil,
                image: nil
            )
            selectAmount(guardian: guardian)
        }
        show(vc)
    }

    func selectAmount(guardian: Guardian) {
        let vc = factory.selectAmount(safe: safe, guardian: guardian) { [unowned self] (guardian, amount) in
            self.guardian = guardian
            self.amount = amount
            review(stepNumber: 4, maxSteps: 4)
        }

        show(vc)
    }

    func review(stepNumber: Int, maxSteps: Int) {
        assert(guardian != nil)
        assert(amount != nil)
        let reviewVC = factory.review(
            safe: safe,
            guardian: guardian,
            amount: amount,
            stepNumber: stepNumber,
            maxSteps: maxSteps) { [unowned self] in
                success(amount: amount)
            }
        show(reviewVC)
    }

    func success(amount: String) {
        let successVC = factory.success (amount: amount) { [unowned self] in
            SafeClaimingController.shared.claimFor(safe: safe.addressValue)
            NotificationCenter.default.post(name: .initiateTxNotificationReceived, object: self, userInfo: nil)
            stop(success: true)
        }

        show(successVC)
    }
}

class ClaimSafeTokenFlowFactory {
    func legalDisclaimer(onAgree: @escaping () -> ()) -> LegalDisclaimerViewController {
        let vc = LegalDisclaimerViewController()
        vc.onAgree = onAgree
        return vc
    }

    func navigatingDAO(onAgree: @escaping () -> ()) -> NavigatingDAOViewController {
        let vc = NavigatingDAOViewController(completion: onAgree)
        return vc
    }

    func claimGetStarted(onStartClaim: @escaping () -> ()) -> ClaimGetStartedViewController {
        let vc = ClaimGetStartedViewController()
        vc.onStartClaim = onStartClaim
        return vc
    }

    func claimNotAvailable() -> ClaimNotAvailableViewController {
        let vc = ClaimNotAvailableViewController()
        return vc
    }

    func chooseDelegateIntro(onChooseGuardian: @escaping () -> (),
                             onCustomAddress: @escaping () -> ()) -> ChooseDelegateIntroViewController{
        let vc = ChooseDelegateIntroViewController(stepNumber: 1,
                                                   maxSteps: 4,
                                                   onChooseGuardian: onChooseGuardian,
                                                   onCustomAddress: onCustomAddress)
        return vc
    }

    func chooseGuardian(_ onSelected: @escaping (Guardian) -> ()) -> SelectGuardianViewController {
        let vc = SelectGuardianViewController()
        vc.onSelected = onSelected
        return vc
    }

    func enterCustomAddress(mainnet: Bool, _ onContinue: @escaping (Address) -> ()) -> EnterCustomAddressViewController {
        let vc = EnterCustomAddressViewController()
        vc.mainnet = mainnet
        vc.onContinue = onContinue
        return vc
    }

    func chooseWhatIsSafe(completion: @escaping () -> ()) -> WhatIsSafeViewController {
        let vc = WhatIsSafeViewController(completion: completion)
        return vc
    }

    func selectAmount(safe: Safe, guardian: Guardian, onClaim: @escaping (Guardian, String) -> ()) -> ClaimingAmountViewController {
        let vc = ClaimingAmountViewController(guardian: guardian, safe: safe, onClaim: onClaim)
        return vc
    }

    func review(
        safe: Safe,
        guardian: Guardian,
        amount: String,
        stepNumber: Int,
        maxSteps: Int,
        newAddressName: String? = nil,
        completion: @escaping () -> Void
    ) -> ReviewClaimSafeTokenTransactionViewController {
        let reviewVC = ReviewClaimSafeTokenTransactionViewController(safe: safe, guardian: guardian, amount: amount)
        reviewVC.stepNumber = stepNumber
        reviewVC.maxSteps = maxSteps
        reviewVC.onSuccess = completion
        return reviewVC
    }


    func success(amount: String,
                 completion: @escaping () -> Void) -> ClaimSuccessViewController {
        let successVC = ClaimSuccessViewController()
        successVC.amount = amount
        successVC.onOk = completion
        return successVC
    }
}
