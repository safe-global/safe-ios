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
    var controller: ClaimingAppController!

    init(safe: Safe,
         controller: ClaimingAppController,
         factory: ClaimSafeTokenFlowFactory = ClaimSafeTokenFlowFactory(),
         completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        self.controller = controller
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
        chooseGuardianVC.safe = safe
        chooseGuardianVC.controller = controller
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

// TODO: refactor with store that stores the current state of the app
// delegate list, shuffled
// selected delegate
// selected user amounts
// etc.

// every vc can work with the store
// token flow can work with the store.

class ClaimSafeTokenFlow: UIFlow {
    var factory: ClaimSafeTokenFlowFactory!
    var safe: Safe
    var amount: Sol.UInt128?
    var selectedGuardian: Guardian?
    var selectedCustomAddress: Address?
    var delegateFlow: SelectDelegateFlow!
    var controller: ClaimingAppController!

    init(safe: Safe,
         factory: ClaimSafeTokenFlowFactory = ClaimSafeTokenFlowFactory(),
         completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        // TODO: switch configuration depending on the safe's chain
        let configuration: ClaimingAppController.Configuration = .rinkeby
        controller = ClaimingAppController(configuration: configuration, chain: safe.chain!)
        super.init(completion: completion)
    }

    override func start() {
        // need to load eligibility status

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
        delegateFlow = SelectDelegateFlow(safe: safe, controller: controller, factory: factory, completion: { [unowned self] _ in
            selectedGuardian = delegateFlow.guardian
            selectedCustomAddress = delegateFlow.customAddress
            selectAmount()
        })
        push(flow: delegateFlow)
    }

    func selectAmount() {
        let claimVC = factory.selectAmount(
            safe: safe,
            delegate: delegateFlow.customAddress,
            guardian: delegateFlow.guardian,
            controller: controller
        )

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
            guardian: delegateFlow.guardian!,
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
        let vc = ChooseDelegateIntroViewController(onChooseGuardian: onChooseGuardian,
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

    func selectAmount(safe: Safe, delegate: Address?, guardian: Guardian?, controller: ClaimingAppController) -> ClaimTokensViewController {
        let vc = ClaimTokensViewController(tokenDelegate: delegate, guardian: guardian, safe: safe, controller: controller)
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
