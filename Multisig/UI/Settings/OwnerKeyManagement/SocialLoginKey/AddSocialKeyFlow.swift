//
//  AddKeyViaSocialFlow.swift
//  Multisig
//
//  Created by Mouaz on 9/4/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import AuthenticationServices

class AddSocialKeyFlow: AddKeyFlow {
    var flowFactory: AddKeyViaSocialFlowFactory {
        factory as! AddKeyViaSocialFlowFactory
    }

    private var appleWeb3AuthLogin: AppleWeb3AuthLogin!
    private var loginModel: GoogleWeb3AuthLoginModel!

    var parameters: AddSocialKeyParameters? {
        keyParameters as? AddSocialKeyParameters
    }

    init(completion: @escaping (Bool) -> Void) {
        super.init(factory: AddKeyViaSocialFlowFactory(), completion: completion)
    }

    override func intro() {
        let vc = flowFactory.addOwnerViaSocialViewController { [weak self] in
            self?.appleLogin()
        } onGoogleAction: { [weak self] in
            self?.googleLogin()
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

                let view = self.flowFactory.creatingViewController()
                ViewControllerFactory.makeTransparentNavigationBar(view)
                self.show(view)
            }, keyGenerationComplete: { [weak self] (key, email, error) in
                guard let `self` = self else { return }
                self.handle(key: key, email: email, keyType: .web3AuthApple, error: error)
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
            let view = self.flowFactory.creatingViewController()
            ViewControllerFactory.makeTransparentNavigationBar(view)
            self.show(view)
        }
        let keyGenerationComplete = { [weak self] (key, email, error) in
            guard let `self` = self else { return }
            self.handle(key: key, email: email, keyType: .web3AuthGoogle, error: error)
        }

        loginModel = GoogleWeb3AuthLoginModel()
        loginModel!.authorizationComplete = authorizationComplete
        loginModel!.keyGenerationComplete = keyGenerationComplete

        loginModel!.loginWithCustomAuth()
    }

    override func doImport() -> Bool {
        guard let key = parameters?.key,
              let name = parameters?.name,
              let email = parameters?.email,
              let type = parameters?.type else {
            assertionFailure("Missing key arguments")
            return false
        }

        return OwnerKeyController.importKey(key,
                                            name: name,
                                            email: email,
                                            type: type)
    }


    func handle(key: String?, email: String?, keyType: KeyType, error: Error?) {
        if let error = error {
            App.shared.snackbar.show(error: GSError.Web3AuthGenericError(underlyingError: error))
            stop(success: false)
            return
        }

        guard let key = key, !key.isEmpty else {
            App.shared.snackbar.show(message: "Key was nil")
            stop(success: false)
            return
        }

        guard let email = email, !email.isEmpty else {
            App.shared.snackbar.show(message: "Email not found")
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

        keyParameters = AddSocialKeyParameters(address: privateKey.address,
                                                    name: nil,
                                                    key: privateKey,
                                                    email: email,
                                                    type: keyType)
        didGetKey()
    }
}

extension AddSocialKeyFlow: ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

class AddKeyViaSocialFlowFactory: AddKeyFlowFactory {
    func addOwnerViaSocialViewController(onAppleAction: @escaping () -> (),
                                         onGoogleAction: @escaping () -> ()) -> AddOwnerViaSocialViewController {
        let vc = AddOwnerViaSocialViewController()
        vc.onAppleAction = onAppleAction
        vc.onGoogleAction = onGoogleAction

        return vc
    }

    func creatingViewController() -> CreatingSocialKeyViewController {
        CreatingSocialKeyViewController()
    }

    override func enterName(parameters: AddKeyParameters, completion: @escaping (String) -> Void) -> EnterAddressNameViewController {
        let vc = super.enterName(parameters: parameters, completion: completion)

        vc.navigationItem.hidesBackButton = true
        vc.navigationItem.largeTitleDisplayMode = .never

        return vc
    }
}

class AddSocialKeyParameters: AddKeyParameters {
    var email: String
    var key: PrivateKey
    init(address: Address, name: String?, key: PrivateKey, email: String, type: KeyType) {
        self.key = key
        self.email = email
        super.init(address: address, name: name, type: type)
    }
}
