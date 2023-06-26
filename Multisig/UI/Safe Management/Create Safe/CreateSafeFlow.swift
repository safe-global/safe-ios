//
//  CreateSafeFlow.swift
//  Multisig
//
//  Created by Mouaz on 6/23/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class CreateSafeFlow: UIFlow {
    var factory: CreateSafeFlowFactory!
    var chain: Chain!
    var safe: Safe!
    var owner: KeyInfo!
    var createPasscodeFlow: CreatePasscodeFlow!
    init(_ factory: CreateSafeFlowFactory = CreateSafeFlowFactory() , completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        chooseNetwork()
    }

    func chooseNetwork() {
        let vc = factory.selectNetworkView { [unowned self] chain in
            self.chain = Chain.createOrUpdate(chain)
            instructions()
        }

        vc.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        show(vc)
    }

    func instructions() {
        if chain.isSupported(feature: Chain.Feature.web3authCreateSafe) {
            web2StyleInstructions()
        } else {
            web3StyleInstructions()
        }
    }

    func web2StyleInstructions() {
        let vc = factory.createSafeWithSocialIntroViewController(chain: chain) {
            // TODO: Create safe with Apple login
        } onGoogle: { [unowned self] in
            creatingSafe()
        } onAddress: { [unowned self] in
            web3StyleInstructions()
        }

        show(vc)
    }

    func web3StyleInstructions() {
        let vc = factory.instructionsViewController(chain: chain) { [unowned self] in
            stop(success: false)
        }

        show(vc)
    }

    func creatingSafe() {
        let vc = factory.creatingSafeViewController()
        show(vc)
    }

    func safeCreationSuccess() {
        let vc = factory.safeCreationSuccess(safe: safe) { [unowned self] in
            enableNotifications()
        }

        show(vc)
    }

    func enableNotifications() {
        let vc = factory.safeAction(imageName: "ico-notifications",
                                    titleText: "Never miss a thing",
                                    descriptionText: "Turn on push notifications to track your wallet activity. You can also do this later.",
                                    primaryActionTitle: "Enable notifications",
                                    secondaryActionTitle: "Skip") {

        } onSeconradyAction: { [unowned self] in
            stop(success: true)
        }

        show(vc)
    }

    func enablePasscode() {
        createPasscodeFlow = CreatePasscodeFlow(completion: { [unowned self] _ in
            createPasscodeFlow = nil
            stop(success: true)
        })
        push(flow: createPasscodeFlow)
    }
}

class CreateSafeFlowFactory {
    func selectNetworkView(completion: @escaping (_ chain: SCGModels.Chain) -> Void) -> SelectNetworkViewController {
        let vc = SelectNetworkViewController()
        vc.showWeb2SupportHint = true
        vc.completion = completion
        vc.screenTitle = "Select network"
        vc.descriptionText = "Your Safe Account will only exist on the selected network."
        
        return vc
    }

    func createSafeWithSocialIntroViewController(chain: Chain,
                                                 onApple: @escaping () -> Void,
                                                 onGoogle: @escaping () -> Void,
                                                 onAddress: @escaping () -> Void) -> CreateSafeWithSocialIntroViewController {
        let instructionsVC = CreateSafeWithSocialIntroViewController()
        instructionsVC.chain = chain
        instructionsVC.onAppleAction = onApple
        instructionsVC.onGoogleAction = onGoogle
        instructionsVC.onAddressAction = onAddress

        return instructionsVC
    }

    func creatingSafeViewController() -> SafeCreatingViewController {
        let vc = SafeCreatingViewController()
        return vc
    }

    func safeCreationSuccess(safe: Safe, completion: @escaping () -> Void) -> SafeCreationSuccessViewController {
        let vc = SafeCreationSuccessViewController()
        vc.safe = safe
        vc.onContinue = completion
        return vc
    }

    func safeAction(imageName: String,
                    titleText: String,
                    descriptionText: String,
                    primaryActionTitle: String,
                    secondaryActionTitle: String,
                    onPrimaryAction: @escaping () -> Void,
                    onSeconradyAction: @escaping () -> Void) -> SafeActionViewController {
        let vc = SafeActionViewController()
        vc.imageName = imageName
        vc.titleText = titleText
        vc.descriptionText = descriptionText
        vc.primaryActionTitle = primaryActionTitle
        vc.secondaryActionTitle = secondaryActionTitle

        return vc
    }

    func instructionsViewController(chain: Chain,
                                    completion: @escaping () -> Void) -> CreateSafeInstructionsViewController {
        let instructionsVC = CreateSafeInstructionsViewController()
        instructionsVC.chain = chain

        instructionsVC.onClose = completion

        return instructionsVC
    }
}
