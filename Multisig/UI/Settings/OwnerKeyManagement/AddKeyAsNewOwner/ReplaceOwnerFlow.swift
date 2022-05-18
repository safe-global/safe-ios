//
//  ReplaceOwnerFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ReplaceOwnerFlow: SafeSettingsChangeFlow {
    var newOwner: AddressInfo
    var ownerToReplace: Address?
    var prevOwner: Address?

    var replaceOwnerFactory: ReplaceOwnerFlowFactory {
        factory as! ReplaceOwnerFlowFactory
    }

    internal init(newOwner: AddressInfo, safe: Safe, factory: ReplaceOwnerFlowFactory = .init(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.newOwner = newOwner
        super.init(safe: safe, factory: factory, navigationController: navigationController, completion: completion)
    }

    override func start() {
        pickOwnerToReplace()
    }

    func pickOwnerToReplace() {
        let pickOwnerToReplaceVC = replaceOwnerFactory.pickOwnerToReplace() { [unowned self] previousOwner, ownerToReplace in
            self.ownerToReplace = ownerToReplace
            self.prevOwner = previousOwner
            review()
        }
        show(pickOwnerToReplaceVC)
    }

    func review() {
        assert(ownerToReplace != nil)
        let reviewVC = replaceOwnerFactory.review(
            step: 2,
            maxSteps: 2,
            safe: safe,
            newOwner: newOwner,
            ownerToReplace: ownerToReplace!,
            previousOwner: prevOwner) { [unowned self] txDetails in
                transaction = txDetails
                success()
            }
        show(reviewVC)
    }

    func success() {
        assert(transaction != nil)
        let successVC = factory.success (bodyText: "It needs to be confirmed and executed first before the owner will be replaced.",
                                         trackingEvent: .replaceOwnerSuccess){ [unowned self] showTxDetails in
            if showTxDetails {
                NotificationCenter.default.post(
                    name: .initiateTxNotificationReceived,
                    object: self,
                    userInfo: ["transactionDetails": transaction!])
            }
            stop(success: !showTxDetails)
        }
        show(successVC)
    }
}

class ReplaceOwnerFlowFactory: FlowFactory {

    func pickOwnerToReplace(onContinue: @escaping (_ previousOwner: Address?, _ ownerToReplace: Address) -> Void) -> SafeOwnerPickerViewController {
        let safeOwnerPickerVC = SafeOwnerPickerViewController()
        safeOwnerPickerVC.onContinue = onContinue
        return safeOwnerPickerVC
    }

    func review(
        step: Int,
        maxSteps: Int,
        safe: Safe,
        newOwner: AddressInfo,
        ownerToReplace: Address,
        previousOwner: Address?,
        completion: @escaping (SCGModels.TransactionDetails) -> Void
    ) -> ReviewReplaceOwnerTxViewController {

        let addOwnerReviewVC = ReviewReplaceOwnerTxViewController(
            safe: safe,
            owner: newOwner,
            ownerToBeReplaced: ownerToReplace,
            previousOwner: previousOwner,
            ownersCount: safe.ownersInfo?.count ?? 0,
            threshold: Int(safe.threshold ?? 0)
        )
        addOwnerReviewVC.stepNumber = step
        addOwnerReviewVC.maxSteps = maxSteps
        addOwnerReviewVC.onSuccess = completion
        return addOwnerReviewVC
    }
}
