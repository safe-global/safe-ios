//
//  ClaimSafeTokenFlow.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter
import Solidity
import UIKit

class SelectDelegateFlow: UIFlow {
    var factory: ClaimSafeTokenFlowFactory!
    var safe: Safe
    var guardian: Guardian?
    var customAddress: Address?
    var controller: ClaimingAppController!
    var animatedStart: Bool
    var crossDissolvedStart: Bool

    init(safe: Safe,
         guardian: Guardian?,
         customAddress: Address?,
         animated: Bool,
         crossDissolved: Bool,
         controller: ClaimingAppController,
         factory: ClaimSafeTokenFlowFactory = ClaimSafeTokenFlowFactory(),
         completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        self.guardian = guardian
        self.customAddress = customAddress
        self.controller = controller
        self.animatedStart = animated
        self.crossDissolvedStart = crossDissolved
        super.init(completion: completion)
    }

    override func start() {
        chooseDelegateIntro()

        if guardian != nil {
            chooseGuardian()
        } else if customAddress != nil {
            enterCustomAddress()
        }

        // resetting to show animation after first start
        animatedStart = true
        crossDissolvedStart = false
    }

    func chooseDelegateIntro() {
        let vc = factory.chooseDelegateIntro { [unowned self] in
            chooseGuardian()
        } onCustomAddress: { [unowned self] in
            enterCustomAddress()
        }
        show(vc, animated: animatedStart, crossDissolve: crossDissolvedStart)
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
        show(chooseGuardianVC, animated: animatedStart, crossDissolve: crossDissolvedStart)
    }

    func enterCustomAddress() {
        Tracker.trackEvent(.screenClaimAddr)
        let isMainnet = self.safe.chain?.id == Chain.ChainID.ethereumMainnet
        let enterAddressVC = factory.enterCustomAddress(mainnet: isMainnet,
                                                        address: customAddress,
                                                        safeAddress: safe.addressValue) { [unowned self] address in
            guardian = nil
            customAddress = address
            Tracker.trackEvent(.userClaimAddrSelect)
            stop(success: true)
        }
        show(enterAddressVC, animated: animatedStart, crossDissolve: crossDissolvedStart)
    }

    func popToSelection() {
        let vcType: UIViewController.Type
        if guardian != nil {
            vcType = GuardianListViewController.self
        } else if customAddress != nil {
            vcType = EnterCustomAddressViewController.self
        } else {
            vcType = ChooseDelegateIntroViewController.self
        }
        guard let vc = navigationController.viewControllers.first(where: { type(of: $0) == vcType }) else {
            return
        }
        customAddress = nil
        guardian = nil
        navigationController.popToViewController(vc, animated: true)
    }

}

class ClaimSafeTokenFlow: UIFlow {
    var factory: ClaimSafeTokenFlowFactory!
    var safe: Safe
    var amount: Sol.UInt128?
    var maxAmountSelected: Bool = false
    var claimData: ClaimingAppController.ClaimingData?
    var timestamp: TimeInterval?
    var selectedGuardian: Guardian?
    var selectedCustomAddress: Address?
    var delegateFlow: SelectDelegateFlow!
    var controller: ClaimingAppController!
    var transactionDetails: SCGModels.TransactionDetails!

    init(safe: Safe,
         factory: ClaimSafeTokenFlowFactory = ClaimSafeTokenFlowFactory(),
         completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        controller = ClaimingAppController(chain: safe.chain!)!
        super.init(completion: completion)
    }

    override func start() {
        let startVC = factory.start()
        startVC.safe = safe
        startVC.controller = controller

        timestamp = Date().timeIntervalSince1970
        startVC.completion = { [unowned self] data in
            claimData = data
            showFirstScreen()
            navigationController.viewControllers.remove(at: 0)
        }

        show(startVC)
    }

    func showFirstScreen() {
        guard let claimData = claimData, claimData.isEligible else {
            showNotAvailable(crossDissolve: true)
            return
        }
        if !claimData.isRedeemed {
            // fresh start
            showIntro(crossDissolve: true)
        } else if let delegate = claimData.delegateAddress, let guardian = claimData.guardian(for: delegate) {
            // guardian found for existing delegate address
            selectedGuardian = guardian
            chooseDelegate(animated: false)
            selectAmount(crossDissolve: true)
        } else if let delegate = claimData.delegateAddress {
            // custom address set as delegate
            selectedCustomAddress = delegate
            chooseDelegate(animated: false)
            selectAmount(crossDissolve: true)
        } else {
            // no delegate address exists, but already redeemed before
            chooseDelegate(crossDissolve: true)
        }
    }

    func showDisclaimer() {
        let vc = factory.legalDisclaimer {[unowned self] in
            chooseDelegate()
        }
        show(vc)
    }

    func showNavigatingDAO() {
        let vc = factory.navigatingDAO {[unowned self] in
            showDisclaimer()
        }
        show(vc)
    }

    func showIntro(crossDissolve: Bool = false) {
        let introVC = factory.claimGetStarted { [unowned self] in
            showWhatIsSafe()
        }
        show(introVC, crossDissolve: crossDissolve)
        introVC.navigationItem.largeTitleDisplayMode = .always
        introVC.navigationController?.navigationBar.prefersLargeTitles = true
    }

    func showNotAvailable(crossDissolve: Bool = false) {
        let vc = factory.claimNotAvailable()
        show(vc, crossDissolve: crossDissolve)
    }

    func showWhatIsSafe() {
        let vc = factory.chooseWhatIsSafe { [unowned self] in
            showTokenDistribution()
        }
        show(vc)
    }

    func showTokenDistribution() {
        let vc = factory.chooseTokenDistribution { [unowned self] in
            showWhatIsSafeToken()
        }
        show(vc)
    }

    func showWhatIsSafeToken() {
        let vc = factory.whatIsSafeToken { [unowned self] in
            showNavigatingDAO()
        }
        show(vc)
    }

    func chooseDelegate(animated: Bool = true, crossDissolve: Bool = false) {
        delegateFlow = SelectDelegateFlow(
            safe: safe,
            guardian: selectedGuardian,
            customAddress: selectedCustomAddress,
            animated: animated,
            crossDissolved: crossDissolve,
            controller: controller,
            factory: factory
        ) { [unowned self] _ in
            selectedGuardian = delegateFlow.guardian
            selectedCustomAddress = delegateFlow.customAddress
            selectAmount()
        }
        push(flow: delegateFlow)
    }

    func selectAmount(crossDissolve: Bool = false) {
        let claimVC = factory.selectAmount(
            safe: safe,
            delegate: selectedCustomAddress,
            guardian: selectedGuardian,
            controller: controller
        )

        claimVC.completion = { [unowned self, unowned claimVC] in
            amount = claimVC.inputAmount
            claimData = claimVC.claimData
            timestamp = claimVC.timestamp
            maxAmountSelected = claimVC.hasSelectedMaxAmount

            review()
        }
        claimVC.onEditDelegate = { [unowned self] in
            delegateFlow.popToSelection()
        }

        show(claimVC, crossDissolve: crossDissolve)
    }

    func review() {
        precondition(selectedCustomAddress != nil || selectedGuardian != nil)
        precondition(amount != nil)
        precondition(claimData != nil)
        precondition(timestamp != nil)

        let reviewVC = ReviewClaimSafeTokenTransactionViewController(
            safe: safe,
            amount: amount!,
            maxAmountSelected: maxAmountSelected,
            claimData: claimData!,
            timestamp: timestamp!,
            guardian: selectedGuardian,
            customAddress: selectedCustomAddress,
            controller: controller
        ) { [unowned self] txDetails in
            transactionDetails = txDetails
            self.success()
        }

        show(reviewVC)
    }

    func success() {
        let successVC = ClaimSuccessViewController()
        successVC.amount = amount
        successVC.guardian = selectedGuardian
        let selectedAddress = (selectedGuardian?.address.address ?? selectedCustomAddress)
        successVC.hasChangedDelegate =
            selectedAddress != nil &&
            selectedAddress != claimData?.delegate.map(Address.init)

        successVC.onOk = { [unowned self] in
            NotificationCenter.default.post(
                name: .initiateTxNotificationReceived,
                object: self,
                userInfo: ["transactionDetails": transactionDetails!])

            stop(success: true)
        }

        successVC.onShare = { [unowned self, unowned successVC] in
            let shareVC = factory.share(transaction: transactionDetails, safe: safe)
            successVC.present(shareVC, animated: true)
        }

        show(successVC)
    }
}

class ClaimSafeTokenFlowFactory {
    func start() -> ClaimSplashViewController {
        let vc = ClaimSplashViewController()
        return vc
    }

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

    func tokenDistribution(onNext: @escaping () -> ()) -> TokenDistributionViewController {
        TokenDistributionViewController(onNext: onNext)
    }

    func whatIsSafe(onNext: @escaping () -> ()) -> WhatIsSafeViewController {
        WhatIsSafeViewController(onNext: onNext)
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

    func enterCustomAddress(mainnet: Bool,
                            address: Address?,
                            safeAddress: Address,
                            _ onContinue: @escaping (Address) -> ()) -> EnterCustomAddressViewController {
        let vc = EnterCustomAddressViewController()
        vc.mainnet = mainnet
        vc.onContinue = onContinue
        vc.address = address
        vc.safeAddress = safeAddress
        return vc
    }

    func chooseWhatIsSafe(onNext: @escaping () -> ()) -> WhatIsSafeViewController {
        let vc = WhatIsSafeViewController(onNext: onNext)
        return vc
    }

    func chooseTokenDistribution(onNext: @escaping () -> ()) -> TokenDistributionViewController {
        let vc = TokenDistributionViewController(onNext: onNext)
        return vc
    }

    func whatIsSafeToken(onNext: @escaping () -> ()) -> WhatIsSafeTokenViewController {
        let vc = WhatIsSafeTokenViewController(onNext: onNext)
        return vc
    }

    func selectAmount(safe: Safe, delegate: Address?, guardian: Guardian?, controller: ClaimingAppController) -> ClaimTokensViewController {
        let vc = ClaimTokensViewController(tokenDelegate: delegate, guardian: guardian, safe: safe, controller: controller)
        return vc
    }

    func share(transaction: SCGModels.TransactionDetails, safe: Safe) -> UIViewController {
        let url = App.configuration.services.webAppURL.appendingPathComponent(
            safe.chain!.shortName! + ":" + safe.displayAddress)
            .appendingPathComponent("transactions")
            .appendingPathComponent(transaction.txId)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        return vc
    }
}
