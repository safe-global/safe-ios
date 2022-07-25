//
//  ClaimSafeTokenFlow.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class ClaimSafeTokenFlow: UIFlow {
    var factory: ClaimSafeTokenFlowFactory!
    var safe: Safe
    var transaction: SCGModels.TransactionDetails?

    init(safe: Safe,
         factory: ClaimSafeTokenFlowFactory = ClaimSafeTokenFlowFactory(),
         completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        showIntro()
    }

    func showIntro() {
        let vc = factory.claimGetStarted { [unowned self] in
            chooseDelegateIntro()
        }
        show(vc)
    }

    func chooseDelegateIntro() {
        let vc = factory.chooseDelegateIntro { [unowned self] in
            chooseGuardian()
        } onCustomAddress: { [unowned self] in
            enterCustomAddress()
        }
        show(vc)
    }

    func chooseGuardian() {
        let vc = factory.chooseGuardian() { [unowned self] guardian in
            selectAmount(guardian: guardian)
        }
        show(vc)
    }

    func enterCustomAddress() {
        let vc = EnterCustomAddressViewController()
        show(vc)
    }

    func selectAmount(guardian: Guardian) {
        let vc = factory.selectAmount(guardian: guardian) { [unowned self] in
            success()
        }

        show(vc)
    }

    func success() {
        //assert(transaction != nil)
        let successVC = factory.success (bodyText: "It needs to be confirmed and executed first before the token claiming.",
                                         trackingEvent: .addAsOwnerSuccess) { [unowned self] showTxDetails in
//            if showTxDetails {
//                NotificationCenter.default.post(
//                    name: .initiateTxNotificationReceived,
//                    object: self,
//                    userInfo: ["transactionDetails": transaction!])
//            }

            stop(success: !showTxDetails)
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

    func chooseDelegateIntro(onChooseGuardian: @escaping () -> (),
                             onCustomAddress: @escaping () -> ()) -> ChooseDelegateIntroViewController{
        let vc = ChooseDelegateIntroViewController(stepNumber: 1,
                                                   maxSteps: 3,
                                                   onChooseGuardian: onChooseGuardian,
                                                   onCustomAddress: onCustomAddress)

        return vc
    }

    func chooseGuardian(_ onSelect: @escaping (Guardian) -> ()) -> ChooseGuardianViewController {
        let vc = ChooseGuardianViewController()
        vc.onSelect = onSelect
        
        return vc
    }

    func selectAmount(guardian: Guardian, onClaim: @escaping () -> ()) -> ClaimingAmountViewController {
        let vc = ClaimingAmountViewController(guardian: guardian, onClaim: onClaim)
        return vc
    }

    func success(bodyText: String,
                 trackingEvent: TrackingEvent,
                 completion: @escaping (_ showTxDetails: Bool) -> Void) -> SuccessViewController {
        let successVC = SuccessViewController(
            titleText: "Your transaction is submitted!",
            bodyText: bodyText,
            primaryAction: "View transaction details",
            secondaryAction: "Done",
            trackingEvent: trackingEvent)
        successVC.onDone = completion
        return successVC
    }
}
