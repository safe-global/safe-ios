//
//  CreatePasswordFlow.swift
//  Multisig
//
//  Created by Mouaz on 8/10/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

class SetupRecoveryKitFlow: UIFlow {
    var factory: SetupRecoveryKitFlowFactory
    private var password: String?

    init(factory: SetupRecoveryKitFlowFactory = SetupRecoveryKitFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        intro()
    }

    func intro() {
        let vc = factory.step(title: "Set up a recovery kit for your owner key",
                              description: "Once set you would need it only in case you lose your device or change it.",
                              action: "Continue",
                              image: "ico-setup-recovery-kit",
                              animation: nil,
                              trackingEvent: .screenStartCreatePassword) { [weak self] in
            self?.instructions()
        }

        vc.navigationItem.largeTitleDisplayMode = .never

        ViewControllerFactory.addCloseButton(vc)
        ViewControllerFactory.removeNavigationBarBorder(vc)
        show(vc)
    }

    func instructions() {
        let vc = factory.instructions(titleText: "How does it work?",
                                      actionText: "Got it, create a password",
                                      image: "ico-setup-recovery-intro",
                                      steps: [.step(number: "1", title: "Create a security password first", description: ""),
                                              .step(number: "2", title: "Your initial email address and the device you’re using are added automatically", description: ""),
                                              .step(number: "3", title: "You are all set!", description: "")]) {[weak self] in
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
        let vc = factory.success(titleText: "Your owner security kit is ready!",
                                 bodyText: "You will need at least 2 factors to restore your key on a new device.",
                                 primaryAction: "Done") { [weak self] in
            App.shared.snackbar.show(message: "Password created")

            self?.stop(success: true)
        }

        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        ViewControllerFactory.addCloseButton(vc)
        ViewControllerFactory.removeNavigationBarBorder(vc)

        show(vc)
    }
}

class SetupRecoveryKitFlowFactory {
    func step(title: String?,
              description: String?,
              action: String?,
              image: String?,
              animation: String?,
              learnMoreURL: URL? = nil,
              trackingEvent: TrackingEvent? = nil,
              learnMoreTrackingEvent: TrackingEvent? = nil,
              onDone: @escaping () -> Void) -> FlowStepViewController {
        FlowStepViewController(titleText: title,
                               descriptionText: description,
                               actionText: action,
                               image: image,
                               animation: animation,
                               learnMoreURL: learnMoreURL,
                               trackingEvent: trackingEvent,
                               learnMoreTrackingEvent: learnMoreTrackingEvent,
                               onDone: onDone)
    }

    func instructions(titleText: String?,
                      actionText: String?,
                      image: String?,
                      steps: [HowDoesItWorkViewController.Step],
                      trackingEvent: TrackingEvent? = nil,
                      onDone: @escaping () -> Void) -> HowDoesItWorkViewController {
        HowDoesItWorkViewController(titleText: titleText,
                                    actionText: actionText,
                                    image: image,
                                    steps: steps,
                                    trackingEvent: trackingEvent,
                                    onDone: onDone)

    }

    func createPassword(completion: @escaping (String) -> Void) -> CreatePasswordViewController {
        CreatePasswordViewController(onDone: completion)
    }

    func success(titleText: String?,
                 bodyText: String?,
                 primaryAction: String?,
                 trackingEvent: TrackingEvent? = nil,
                 onDone: @escaping () -> Void) -> UpdateRecoveryKitSuccessViewController {
        UpdateRecoveryKitSuccessViewController(titleText: titleText,
                                               bodyText: bodyText,
                                               primaryAction: primaryAction,
                                               trackingEvent: trackingEvent,
                                               onDone: onDone)
    }
}

