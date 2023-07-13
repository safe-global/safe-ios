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
    func updateUI(model: CreateSafeFormUIModel) {
        //dump(model, name: "CreateSafeFormUIModel")
        App.shared.snackbar.show(message: "updateUI()")
    }
    
    func createSafeModelDidFinish() {
        LogService.shared.debug("createSafeModelDidFinish()")
        App.shared.snackbar.show(message: "createSafeModelDidFinish()")
    }
    
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    var factory: CreateSafeFlowFactory!
    var chain: Chain!
    var txHash: String?
    var safe: Safe?
    var owner: KeyInfo!
    var createPasscodeFlow: CreatePasscodeFlow!
    private var relayingTask: URLSessionTask?
    let relayerService: SafeGelatoRelayService = App.shared.relayService
    private var appleWeb3AuthLogin: AppleWeb3AuthLogin!
    private let uiModel = CreateSafeFormUIModel()
    
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
        handleAuthorizationAppleIDButtonPress()

        // TODO: submit create safe tx
    }

    func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        appleWeb3AuthLogin = AppleWeb3AuthLogin(
            authorizationComplete: {
                let view = SafeCreatingViewController()
                view.onSuccess = {
                    self.safeCreationSuccess()
                }
                self.show(view)
            }, keyGenerationComplete: { key in
                // TODO: Use key to start the safe creation process here (separate PR)
                LogService.shared.debug("key: \(key)")
                self.startCreateSafe(key)
            }
        )

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        authorizationController.delegate = appleWeb3AuthLogin
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func googleLogin() {
        // TODO: Fix login via google
        let loginModel = GoogleWeb3AuthLoginModel { key in
            
            
            // TODO: Safe key to database
            
            
            self.startCreateSafe(key)
            
            let view = SafeCreatingViewController()
            view.onSuccess = {
                self.safeCreationSuccess()
            }
            self.show(view)
        }

        loginModel.loginWithCustomAuth(caller: navigationController)
        
        
    }
    
    func startCreateSafe(_ key: String?) {
        
        // TODO: submit create safe tx
        guard let key = key else {
            App.shared.snackbar.show(message: "key was nil")
            return
        }
        let privateKey = try? PrivateKey(data: Data(ethHex: key))
        dump(privateKey, name: "PrivateKey")
        
        guard let privateKey = privateKey else {
            App.shared.snackbar.show(message: "Couldn't create key from: [\(key)]")
            return
        }
        var keyInfo: KeyInfo? = try? KeyInfo.firstKey(address: privateKey.address)
        if keyInfo == nil {
            do {
                keyInfo =  try KeyInfo.import(address: privateKey.address, name: "New Apple key", privateKey: privateKey, type: .web3AuthApple)
            } catch {
                App.shared.snackbar.show(message: "\(error.localizedDescription)" )
            }
        }
        uiModel.delegate = self
        //        if let txHash = txHash,
        //           let safeCreationCall = SafeCreationCall.by(txHashes: [txHash], chainId: chain.id!)?.first {
        //            uiModel.updateWithSafeCall(call: safeCreationCall)
        //        }
        
        uiModel.start()
        uiModel.chain = chain
        uiModel.setName("Neuer Safe")
        uiModel.selectedKey = keyInfo
        
        let address: Address? = keyInfo?.address
        LogService.shared.debug("Address: \(address)")
        uiModel.addOwnerAddress(address!)
        
        dump(keyInfo, name:"keyInfo")
        
        uiModel.estimate { result in
            self.uiModel.relaySubmit()
        }
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
