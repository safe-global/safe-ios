//
//  SafeSettingsChangeFlow.swift
//  Multisig
//
//  Created by Moaaz on 5/17/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class SafeSettingsChangeFlow: UIFlow {
    var factory: SafeSettingsFlowFactory!
    var safe: Safe
    var transaction: SCGModels.TransactionDetails?

    init(safe: Safe, factory: SafeSettingsFlowFactory, navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        super.init(navigationController: navigationController, completion: completion)
    }
}


class SafeSettingsFlowFactory {
    func confirmations(
        confirmations: Int,
        minConfirmations: Int,
        maxConfirmations: Int,
        stepNumber: Int,
        maxSteps: Int,
        promptText: String,
        trackingEvent: TrackingEvent,
        completion: @escaping (_ newConfirmations: Int) -> Void
    ) -> EditConfirmationsViewController {
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = confirmations
        confirmationsVC.minConfirmations = minConfirmations
        confirmationsVC.maxConfirmations = maxConfirmations
        confirmationsVC.stepNumber = stepNumber
        confirmationsVC.maxSteps = maxSteps
        confirmationsVC.trackingEvent = trackingEvent
        confirmationsVC.promptText = promptText
        confirmationsVC.completion = completion
        return confirmationsVC
    }

    func enterOwnerAddress(chain: Chain,
                           stepNumber: Int,
                           maxSteps: Int,
                           trackingEvent: TrackingEvent,
                           completion: @escaping (Address, String?) -> Void) -> EnterOwnerAddressViewController {
        let enterOwnerAddressVC = EnterOwnerAddressViewController()
        enterOwnerAddressVC.stepNumber = 1
        enterOwnerAddressVC.maxSteps = 3
        enterOwnerAddressVC.trackingEvent = trackingEvent
        enterOwnerAddressVC.chain = chain
        enterOwnerAddressVC.completion = completion

        return enterOwnerAddressVC
    }

    func enterOwnerName(safe: Safe,
                        address: Address,
                        stepNumber: Int,
                        maxSteps: Int,
                        trackingEvent: TrackingEvent,
                        completion: @escaping (String) -> Void) -> EnterOwnerNameViewController {
        let enterNameVC = EnterOwnerNameViewController()
        enterNameVC.address = address
        enterNameVC.prefix = safe.chain!.shortName
        enterNameVC.completion = completion
        enterNameVC.trackingEvent = trackingEvent
        enterNameVC.stepNumber = stepNumber
        enterNameVC.maxSteps = maxSteps
        
        return enterNameVC
    }

    func success(bodyText: String, trackingEvent: TrackingEvent, completion: @escaping (_ showTxDetails: Bool) -> Void) -> SuccessViewController {
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
