//
//  ClaimSafeTokenFlow.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter


class SelectDelegateFlow: UIFlow {
    var factory: ClaimSafeTokenFlowFactory!
    var safe: Safe
    var guardian: Guardian?
    var customAddress: Address?

    init(safe: Safe,
         guardian: Guardian? = nil,
        customAddress: Address? = nil,
         factory: ClaimSafeTokenFlowFactory = ClaimSafeTokenFlowFactory(),
         completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        chooseDelegateIntro()
    }

    func chooseDelegateIntro() {
        let vc = factory.chooseDelegateIntro { [unowned self] in
            chooseGuardian()
        } onCustomAddress: { [unowned self] in
            enterCustomAddress()
        }
        show(vc)
        vc.navigationItem.largeTitleDisplayMode = .always
        vc.navigationController?.navigationBar.prefersLargeTitles = true
    }

    func chooseGuardian() {
        let chooseGuardianVC = factory.chooseGuardian() { [unowned self] selectedGuardian in
            guardian = selectedGuardian
            customAddress = nil
            stop(success: true)
        }
        show(chooseGuardianVC)
    }

    func enterCustomAddress() {
        let enterAddressVC = factory.enterCustomAddress(mainnet: self.safe.chain?.id == Chain.ChainID.ethereumMainnet) { [unowned self] address in
            guardian = nil
            customAddress = address
            stop(success: true)
        }
        show(enterAddressVC)
    }

    func popToStart() {
        guard let vc = navigationController.viewControllers.first(where: { $0 is ChooseDelegateIntroViewController }) else {
            return
        }
        navigationController.popToViewController(vc, animated: true)
    }

}

import Solidity

class ClaimSafeTokenFlow: UIFlow {
    var factory: ClaimSafeTokenFlowFactory!
    var safe: Safe
    var amount: Sol.UInt128?
    var selectedGuardian: Guardian?
    var selectedCustomAddress: Address?
    var delegateFlow: SelectDelegateFlow!

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
            // if available show intro
           showIntro()
        }
    }

    func showIntro() {
        let introVC = factory.claimGetStarted { [unowned self] in
            chooseDelegate()  // TODO: Jump to Tutorial
        }
        show(introVC)
        introVC.navigationItem.largeTitleDisplayMode = .always
        introVC.navigationController?.navigationBar.prefersLargeTitles = true
    }

    func showNotAvailable() {
        let vc = factory.claimNotAvailable()
        show(vc)
    }

    func chooseDelegate() {
        delegateFlow = SelectDelegateFlow(safe: safe, guardian: selectedGuardian, customAddress: selectedCustomAddress, factory: factory, completion: { [unowned self] _ in
            selectedGuardian = delegateFlow.guardian
            selectedCustomAddress = delegateFlow.customAddress
            selectAmount()
        })
        push(flow: delegateFlow)
    }

    func selectAmount() {
        // TODO: retain the entered amount
        let claimVC = factory.selectAmount(safe: safe, delegate: delegateFlow.customAddress, guardian: delegateFlow.guardian)

        claimVC.completion = { [unowned self] in
            review(stepNumber: 4, maxSteps: 4)
        }
        claimVC.onEditDelegate = { [unowned self] in
            delegateFlow.popToStart()
        }

        show(claimVC)
    }

    func review(stepNumber: Int, maxSteps: Int) {
        assert(delegateFlow.customAddress != nil || delegateFlow.guardian != nil)
        assert(amount != nil)
        let reviewVC = factory.review(
            safe: safe,
            guardian: delegateFlow.guardian!, // FIXME: needs change
            amount: "0",
            stepNumber: stepNumber,
            maxSteps: maxSteps) { [unowned self] in
                success(amount: "0")
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

    func chooseGuardian(_ onSelected: @escaping (Guardian) -> ()) -> GuardianListViewController {
        let vc = GuardianListViewController()
        vc.onSelected = onSelected
        return vc
    }

    func enterCustomAddress(mainnet: Bool, _ onContinue: @escaping (Address) -> ()) -> EnterCustomAddressViewController {
        let vc = EnterCustomAddressViewController()
        vc.mainnet = mainnet
        vc.onContinue = onContinue
        return vc
    }

    func selectAmount(safe: Safe, delegate: Address?, guardian: Guardian?) -> ClaimTokensViewController {
        let vc = ClaimTokensViewController(tokenDelegate: delegate, guardian: guardian, safe: safe)
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
