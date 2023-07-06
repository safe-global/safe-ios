//
//  CreateSafeFlow.swift
//  Multisig
//
//  Created by Mouaz on 6/23/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import AuthenticationServices

class CreateSafeFlow: UIFlow, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }

    var factory: CreateSafeFlowFactory!
    var chain: Chain!
    var safe: Safe?
    var owner: KeyInfo!
    var createPasscodeFlow: CreatePasscodeFlow!
    private var relayingTask: URLSessionTask?
    let relayerService: SafeGelatoRelayService = App.shared.relayService
    private var appleWeb3AuthLogin: AppleWeb3AuthLogin!

    init(_ factory: CreateSafeFlowFactory = CreateSafeFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
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
        let vc: CreateSafeWithSocialIntroViewController = factory.createSafeWithSocialIntroViewController(
            chain: chain,
            onApple: { [unowned self] in
                appleLogin()
            }, onGoogle: { [unowned self] in
                googleLogin()
            }, onAddress: { [unowned self] in
                web3StyleInstructions()
            })

        show(vc)
    }

    func web3StyleInstructions() {
        let vc = factory.instructionsViewController(chain: chain) { [unowned self] in
            stop(success: false)
        }

        show(vc)
    }

    func appleLogin() {
        handleAuthorizationAppleIDButtonPress(vc: self.navigationController)
//        showLoginViewController { [unowned self] in
//            creatingSafe()
//        }
        //        show(vc)

        // TODO: Create login via apple
        // This line is not needed after this method implementation
        //        creatingSafe()
        // TODO: submit create safe tx
    }

    func handleAuthorizationAppleIDButtonPress(vc: UIViewController) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        appleWeb3AuthLogin = AppleWeb3AuthLogin {
            print(" onclose called....")


        }

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        authorizationController.delegate = appleWeb3AuthLogin
        authorizationController.presentationContextProvider = self // vc
        authorizationController.performRequests()

        //appleWeb3AuthLogin.loginWithCustomAuth(caller: vc)
    }

    func googleLogin() {
        // TODO: Fix login via google
        let loginModel = GoogleWeb3AuthLoginModel {
            let view = SafeCreatingViewController()
            self.show(view)
        }

        loginModel.loginWithCustomAuth(caller: navigationController)
        // TODO: submit create safe tx
    }

    func creatingSafe() {
        let vc = factory.creatingSafeViewController()
        vc.onSuccess = { [unowned self] in
            safeCreationSuccess()
        }
        navigationController.setNavigationBarHidden(true, animated: true)
        show(vc)
    }

    func safeCreationSuccess() {
        let vc = factory.safeCreationSuccess(safe: safe, chain: chain) { [unowned self] in
            enableNotifications()
        }

        show(vc)
    }

    func enableNotifications() {
        let vc = factory.safeAction(imageName: "ico-notifications",
                                    titleText: "Never miss a thing",
                                    descriptionText: "Turn on push notifications to track your wallet activity. You can also do this later.",
                                    primaryActionTitle: "Enable notifications",
                                    secondaryActionTitle: "Skip") { [unowned self] in
            // TODO: register for notifications after safe created and before calling create passcode flow
            enablePasscode()
        } onSeconradyAction: { [unowned self] in
            stop(success: true)
        }

        navigationController.setNavigationBarHidden(true, animated: true)
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

    func safeCreationSuccess(safe: Safe!, chain: Chain, completion: @escaping () -> Void) -> SafeCreationSuccessViewController {
        let vc = SafeCreationSuccessViewController()
        vc.safe = safe
        vc.chain = chain
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
        vc.onPrimaryAction = onPrimaryAction
        vc.onSeconradyAction = onSeconradyAction

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
