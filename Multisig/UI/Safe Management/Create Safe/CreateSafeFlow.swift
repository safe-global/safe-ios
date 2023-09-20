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
    private let relayerService: SafeGelatoRelayService = App.shared.relayService
    private var appleWeb3AuthLogin: AppleWeb3AuthLogin!
    private let uiModel = CreateSafeFormUIModel()
    private var didSubmit = false
    private var loginModel: GoogleWeb3AuthLoginModel!
    private var inputChainId: String?

    init(chainId: String? = nil, _ factory: CreateSafeFlowFactory = CreateSafeFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        self.inputChainId = chainId
        super.init(completion: completion)
    }

    override func start() {
        chooseNetwork()
    }

    func chooseNetwork() {
        let vc = factory.selectNetworkViewController(chainId: inputChainId) { [unowned self] chain in
            self.chain = Chain.createOrUpdate(chain)
            instructions()
        }

        vc.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        show(vc)
    }

    func instructions() {
        if AppConfiguration.FeatureToggles.socialLogin,
           chain.isSupported(feature: Chain.Feature.web3authCreateSafe) {
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
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        appleWeb3AuthLogin = AppleWeb3AuthLogin(
            authorizationComplete: { [weak self] in
                guard let self = self else { return }
                
                let view = self.factory.safeCreatingViewController()
                view.onSuccess = { [weak self] in
                    self?.stop(success: true)
                }
                self.navigationController.setNavigationBarHidden(true, animated: true)
                self.show(view)
            }, keyGenerationComplete: { [weak self] (key, email, error) in
                self?.storeKeyAndCreateSafe(key: key, email: email, keyType: .web3AuthApple, error: error)
            }
        )

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        authorizationController.delegate = appleWeb3AuthLogin
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func googleLogin() {
        let authorizationComplete = { [weak self] in
            guard let self = self else { return }
            let view = self.factory.safeCreatingViewController()
            view.onSuccess = { [weak self] in
                self?.stop(success: true)
            }
            self.navigationController.setNavigationBarHidden(true, animated: true)
            self.show(view)
        }
        let keyGenerationComplete = { [weak self] (key, email, error) in
            self?.storeKeyAndCreateSafe(key: key, email: email, keyType: .web3AuthGoogle, error: error)
        }

        if loginModel == nil {
            loginModel = GoogleWeb3AuthLoginModel()
        }
        loginModel!.authorizationComplete = authorizationComplete
        loginModel!.keyGenerationComplete = keyGenerationComplete

        loginModel!.loginWithCustomAuth()
    }

    func storeKeyAndCreateSafe(key: String?, email: String?, keyType: KeyType, error: Error?) -> Void {
        if let error = error {
            App.shared.snackbar.show(error: GSError.Web3AuthGenericError(underlyingError: error))
            stop(success: false)
            return
        }
        
        guard let key = key else {
            App.shared.snackbar.show(message: "Key was nil")
            stop(success: false)
            return
        }
        
        let privateKey: PrivateKey
        do {
            privateKey = try PrivateKey(data: Data(ethHex: key))
        } catch {
            App.shared.snackbar.show(message: "Failed to create a private key (\(error.localizedDescription)).")
            stop(success: false)
            return
        }

        var keyInfo: KeyInfo?
        do {
            keyInfo = try KeyInfo.firstKey(address: privateKey.address)
        } catch {
            App.shared.snackbar.show(message: "Failed to get a key (\(error.localizedDescription))")
            stop(success: false)
            return
        }
        
        if keyInfo == nil {
            do {
                keyInfo = try KeyInfo.import(
                    address: privateKey.address,
                    name: email ?? "email withheld",
                    privateKey: privateKey,
                    type: keyType,
                    email: email
                )
            } catch {
                App.shared.snackbar.show(message: "Failed to import key (\(error.localizedDescription))")
                stop(success: false)
                return
            }
        }

        // Notify the UI observer
        NotificationCenter.default.post(name: .safeAccountOwnerCreated, object: nil)

        uiModel.delegate = self
        uiModel.start()
        uiModel.chain = chain
        uiModel.setName("My Safe Account")
        
        if let address = keyInfo?.address {
            uiModel.addOwnerAddress(address)
        }
    }

    // NOTE: This set of methods is unused because it was crashing the app
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
        enablePasscode()
        return

        let vc = factory.safeAction(imageName: "ico-notifications",
                                    titleText: "Never miss a thing",
                                    descriptionText: "Turn on push notifications to track your wallet activity. You can also do this later.",
                                    primaryActionTitle: "Enable notifications",
                                    secondaryActionTitle: "Skip") { [unowned self] in
            enablePasscode()
        } onSecondaryAction: { [unowned self] in
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
    // END OF NOTE

    // CreateSafeFormUIModelDelegate protocol methods
    func updateUI(model: CreateSafeFormUIModel) {
        if model.state == .ready && !didSubmit {
            model.relaySubmit()
            didSubmit = true
        } else if model.state == .error {
            let error = model.gsError ?? GSError.Web3AuthGenericError(underlyingError: "Failed to create a Safe")
            App.shared.snackbar.show(error: error)
            self.stop(success: false)
        }
    }

    func createSafeModelDidFinish() {
        NotificationCenter.default.post(name: .web3AuthSafeCreationUpdate, object: nil)
    }
}

class CreateSafeFlowFactory {
    func selectNetworkViewController(chainId: String? = nil, completion: @escaping (_ chain: SCGModels.Chain) -> Void) -> SelectNetworkViewController {
        let vc = SelectNetworkViewController()
        vc.preselectedChainId = chainId
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
