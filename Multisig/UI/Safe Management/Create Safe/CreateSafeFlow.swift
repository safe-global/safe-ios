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


class CreateSafeFlow: UIFlow, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate, CreateSafeFormUIModelDelegate {
    
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
    private let uiModel = CreateSafeFormUIModel()
    private var didSubmit = false
    
    init(_ factory: CreateSafeFlowFactory = CreateSafeFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        chooseNetwork()
    }

    func chooseNetwork() {
        let vc = factory.selectNetworkViewController { [unowned self] chain in
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
        handleAuthorizationAppleIDButtonPress()
    }

    func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        appleWeb3AuthLogin = AppleWeb3AuthLogin(
            authorizationComplete: {
                let view = self.factory.safeCreatingViewController()
                view.onSuccess = {
                    self.stop(success: true)
                }
                self.show(view)
            }, keyGenerationComplete: { (key, email) in
                self.storeKeyAndCreateSafe(key: key, email: email, keyType: .web3AuthApple )
            }
        )

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        authorizationController.delegate = appleWeb3AuthLogin
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func googleLogin() {
        let loginModel = GoogleWeb3AuthLoginModel(authorizationComplete: {
            let view = self.factory.safeCreatingViewController()
            view.onSuccess = {
                self.stop(success: true)
            }
            self.show(view)

        } , keyGenerationComplete: { [weak self] key, email in
            self?.storeKeyAndCreateSafe(key: key, email: email, keyType: .web3AuthGoogle)
        })

        loginModel.loginWithCustomAuth()
    }
    
    func storeKeyAndCreateSafe(key: String?, email: String?, keyType: KeyType) {
        
        guard let key = key else {
            App.shared.snackbar.show(message: "Key was nil")
            return
        }
        let privateKey = try? PrivateKey(data: Data(ethHex: key))
        
        guard let privateKey = privateKey else {
            App.shared.snackbar.show(message: "Couldn't create private key from: [\(key)]")
            return
        }
        var keyInfo: KeyInfo? = try? KeyInfo.firstKey(address: privateKey.address)
        if keyInfo == nil {
            do {
                keyInfo =  try KeyInfo.import(
                    address: privateKey.address,
                    name: email ?? "email withheld",
                    privateKey: privateKey,
                    type: keyType,
                    email: email
                )
            } catch {
                App.shared.snackbar.show(message: "\(error.localizedDescription)" )
            }
        }

        NotificationCenter.default.post(name: .safeAccountOwnerCreated, object: nil)

        uiModel.delegate = self
        uiModel.start()
        uiModel.chain = chain
        uiModel.setName("My Safe Account")
        if let address = keyInfo?.address {
            uiModel.addOwnerAddress(address)
        }
    }

    func creatingSafe() {
        let vc = factory.safeCreatingViewController()
        vc.onSuccess = { [unowned self] in
            safeCreationSuccess()
        }
        navigationController.setNavigationBarHidden(true, animated: true)
        show(vc)
    }

    func safeCreationSuccess() {
        let vc = factory.safeCreationSuccessViewController(safe: safe, chain: chain) { [unowned self] in
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
            Tracker.trackEvent(.userNotificationsEnable)
            enablePasscode()
        } onSecondaryAction: { [unowned self] in
            Tracker.trackEvent(.userNotificationsSkip)
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
    
    
    // CreateSafeFormUIModelDelegate protocol methods
    func updateUI(model: CreateSafeFormUIModel) {
        if model.state == .ready && !didSubmit {
            model.relaySubmit()
            didSubmit = true
        } else if model.state == .error {
            LogService.shared.error("---> updateUI() called: state: \(model.state)")
        }
    }
    
    func createSafeModelDidFinish() {
        NotificationCenter.default.post(name: .safeCreationUpdate, object: nil)
    }
}

class CreateSafeFlowFactory {
    func selectNetworkViewController(completion: @escaping (_ chain: SCGModels.Chain) -> Void) -> SelectNetworkViewController {
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

    func safeCreatingViewController() -> SafeCreatingViewController {
        let vc = SafeCreatingViewController()
        return vc
    }

    func safeCreationSuccessViewController(safe: Safe!, chain: Chain, completion: @escaping () -> Void) -> SafeCreationSuccessViewController {
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
                    onSecondaryAction: @escaping () -> Void) -> SafeActionViewController {
        let vc = SafeActionViewController()
        vc.imageName = imageName
        vc.titleText = titleText
        vc.descriptionText = descriptionText
        vc.primaryActionTitle = primaryActionTitle
        vc.secondaryActionTitle = secondaryActionTitle
        vc.onPrimaryAction = onPrimaryAction
        vc.onSecondaryAction = onSecondaryAction

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
