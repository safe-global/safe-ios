//
//  CreatePasswordFlow.swift
//  Multisig
//
//  Created by Mouaz on 8/10/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

class CreatePasswordFlow: UIFlow {
    var factory: CreatePasswordFlowFactory
    private var password: String?

    init(factory: CreatePasswordFlowFactory = CreatePasswordFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        intro()
    }

    func intro() {
        let vc = factory.step(title: "Create a security password",
                              description: "This password will be used to access your social key and serve as a recovery factor.",
                              action: "Continue",
                              image: "ico-create-password-intro",
                              animation: nil,
                              trackingEvent: .screenStartCreatePassword) { [weak self] in
            self?.createPasswordView()
        }

        vc.navigationItem.largeTitleDisplayMode = .never

        ViewControllerFactory.addCloseButton(vc)
        ViewControllerFactory.removeNavigationBarBorder(vc)
        show(vc)
    }

    func createPasswordView() {
        let vc = factory.createPassword { [weak self] password in
            guard let `self` = self else { return }
            self.password = password
            createPassword()
        }

        vc.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        ViewControllerFactory.removeNavigationBarBorder(vc)

        show(vc)
    }

    func createPassword() {
        success()
    }

    func success() {
        let vc = factory.step(title: "Password was successfully set up as a recovery factor",
                              description: "If you lose access to another factor, you will be able to use your password to get access to your key.",
                              action: "Done",
                              image: nil,
                              animation: navigationController.isDarkMode ? "successAnimationDark" : "successAnimation",
                              trackingEvent: .screenCreatePasswordSuccess) { [weak self] in
            App.shared.snackbar.show(message: "Password created")
            
            self?.stop(success: true)
        }

        ViewControllerFactory.makeTransparentNavigationBar(vc)

        show(vc)
    }
}

class CreatePasswordFlowFactory {
    func step(title: String?,
              description: String?,
              action: String?,
              image: String?,
              animation: String?,
              trackingEvent: TrackingEvent? = nil,
              onDone: @escaping () -> Void) -> FlowStepViewController {
        let stepViewController = FlowStepViewController(titleText: title,
                                                        descriptionText: description,
                                                        actionText: action,
                                                        image: image,
                                                        animation: animation,
                                                        trackingEvent: trackingEvent,
                                                        onDone: onDone)
        return stepViewController
    }

    func createPassword(completion: @escaping (String) -> Void) -> CreatePasswordViewController {
        CreatePasswordViewController(onDone: completion)
    }
}

