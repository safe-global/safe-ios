//
//  SafeSettingsChangeFlow.swift
//  Multisig
//
//  Created by Moaaz on 5/17/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

/// Basis for flows that create transactions to change Safe Account settings, such as
/// owner structure or required confirmations.
class SafeSettingsChangeFlow: UIFlow {
    var factory: SafeSettingsFlowFactory!
    var safe: Safe
    var transaction: SCGModels.TransactionDetails?

    init(safe: Safe, factory: SafeSettingsFlowFactory, completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        super.init(completion: completion)
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

    func enterOwnerAddress(safe: Safe,
                           stepNumber: Int,
                           maxSteps: Int,
                           title: String,
                           trackingEvent: TrackingEvent,
                           completion: @escaping (Address, String?) -> Void) -> EnterOwnerAddressViewController {
        let enterOwnerAddressVC = EnterOwnerAddressViewController()
        enterOwnerAddressVC.stepNumber = 1
        enterOwnerAddressVC.maxSteps = 3
        enterOwnerAddressVC.trackingEvent = trackingEvent
        enterOwnerAddressVC.safe = safe
        enterOwnerAddressVC.completion = completion
        enterOwnerAddressVC.title = title
        return enterOwnerAddressVC
    }

    func enterOwnerName(safe: Safe,
                        address: Address,
                        name: String? = nil,
                        stepNumber: Int,
                        maxSteps: Int,
                        title: String,
                        trackingEvent: TrackingEvent,
                        trackingParameters: [String: Any]? = nil,
                        completion: @escaping (String) -> Void) -> EnterOwnerNameViewController {
        let enterNameVC = EnterOwnerNameViewController()
        enterNameVC.address = address
        enterNameVC.name = name
        enterNameVC.prefix = safe.chain!.shortName
        enterNameVC.completion = completion
        enterNameVC.trackingEvent = trackingEvent
        enterNameVC.stepNumber = stepNumber
        enterNameVC.maxSteps = maxSteps
        enterNameVC.title = title

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
