//
//  BackupController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class UIFlow {

    var navigationController: UINavigationController
    var completion: (_ success: Bool) -> Void

    internal init(navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.navigationController = navigationController
        self.completion = completion
    }

    func start() {

    }

    func stop(success: Bool) {
        completion(success)
    }

    func show(_ vc: UIViewController) {
        if navigationController.viewControllers.isEmpty {
            navigationController.viewControllers = [vc]
        } else {
            navigationController.show(vc, sender: navigationController)
        }
    }

}

//
// Rationale for implementing UI navigation with a "flow", "factory", and separate view controllers.
//
// I want view controllers to be usable in different contexts --> isolate them
// I want to create view controllers with parameters in different flows --> use factory pattern
// I want the whole flow to be defined in one place --> create an object for that ('flow')
// I want the flow to be integratable into existing navigation stack --> pass the navigation controller to work with
// I want the flow to be stand-alone when opened from different places in the app --> create a navigation controller for the standalone case
// I want to have variations in the flows based on where it should be opened or based on the passed in parameters --> sub-class or enum/bool flags. If more variations can be added in the future, then it is better to subclass.
//
class BackupFlow: UIFlow {
    // Backup flow variation for suggesting backup after generating a key:
    //
    // existing navigation -> intro -> seed -> verify -> success -> completed
    //                              \
    //                               -> canceled

    var mnemonic: String
    var factory: BackupFlowFactory

    init(mnemonic: String, factory: BackupFlowFactory = BackupFlowFactory(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.mnemonic = mnemonic
        self.factory = factory
        super.init(navigationController: navigationController, completion: completion)
    }

    override func start() {
        intro()
    }

    func intro() {
        let intro = factory.intro { [unowned self] shouldStartBackup in
            if shouldStartBackup {
                seed()
            } else {
                stop(success: false)
            }
        }
        intro.navigationItem.hidesBackButton = true
        show(intro)
    }

    func seed() {
        let seed = factory.seed(mnemonic: mnemonic) { [unowned self] in
            verify()
        }
        show(seed)
    }

    func verify() {
        let verify = factory.verify(mnemonic: mnemonic) { [unowned self] in
            updateKey()
            success()
        }
        show(verify)
    }

    func updateKey() {
        guard let privateKey = (try? PrivateKey(mnemonic: mnemonic, pathIndex: 0)) else { return }
        let keyItem = try? KeyInfo.firstKey(address: privateKey.address)
        keyItem?.backedup = true
        keyItem?.save()
        NotificationCenter.default.post(name: .ownerKeyBackedUp, object: nil)
    }

    func success() {
        let success = factory.success { [unowned self] didTapPrimary in
            stop(success: true)
        }
        show(success)
    }
}

class ModalBackupFlow: BackupFlow {
    // Modification of the base backup flow to make it a standalone:
    //
    // modal -> passcode -> seed -> verify -> success -> completed
    //                    \
    //                     -> canceled

    weak var presenter: UIViewController!

    convenience init?(keyInfo: KeyInfo, presenter: UIViewController, factory: BackupFlowFactory = BackupFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        guard let mnemonic = try? keyInfo.privateKey()?.mnemonic else {
            return nil
        }
        self.init(mnemonic: mnemonic, presenter: presenter, factory: factory, completion: completion)
    }

    init(mnemonic: String, presenter: UIViewController, factory: BackupFlowFactory = BackupFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.presenter = presenter
        let navigationController = CancellableNavigationController()
        super.init(mnemonic: mnemonic,
                   factory: factory,
                   navigationController: navigationController,
                   completion: completion)

        navigationController.onCancel = { [unowned self] in
            stop(success: false)
        }
    }

    override func start() {
        passcode()
        // guaranteed to exist at this point
        let rootVC = navigationController.viewControllers.first!
        ViewControllerFactory.addCloseButton(rootVC)
        presenter.present(navigationController, animated: true)
    }

    func passcode() {
        let factory = PasscodeFlowFactory()
        let enterVC = factory.enter(biometry: false, options: [], reset: { [unowned self] in
            stop(success: false)
        }, completion: { [unowned self] success in
            if success {
                seed()
            } else {
                stop(success: false)
            }
        })
        if let enterVC = enterVC {
            show(enterVC)
        } else {
            seed()
        }
    }

    override func seed() {
        super.seed()
        guard let vc = navigationController.viewControllers.last else { return }
        ViewControllerFactory.addCloseButton(vc)
    }

    override func stop(success: Bool) {
        presenter.dismiss(animated: true) { [unowned self] in
            completion(success)
        }
    }
}

class BackupFlowFactory {
    func intro(completion: @escaping (_ shouldStartBackup: Bool) -> Void) -> BackupIntroViewController {
        let introVC = BackupIntroViewController()
        introVC.backupCompletion = completion
        return introVC
    }

    func seed(mnemonic: String, completion: @escaping () -> Void) -> BackupSeedPhraseViewController {
        let backupVC = BackupSeedPhraseViewController()
        backupVC.set(mnemonic: mnemonic)
        backupVC.onContinue = completion
        return backupVC
    }

    func verify(mnemonic: String, completion: @escaping () -> Void) -> VerifyPhraseViewController {
        let verifyVC = VerifyPhraseViewController()
        verifyVC.set(mnemonic: mnemonic)
        verifyVC.completion = completion
        return verifyVC
    }

    func success(completion: @escaping (_ didTapPrimary: Bool) -> Void) -> SuccessViewController {
        let successVC = SuccessViewController(
            titleText: "Your key is backed up!",
            bodyText: "If you lose your phone, you can recover this key with the seed phrase you just backed up.",
            primaryAction: "OK, great",
            secondaryAction: nil,
            trackingEvent: .backupCreatedSuccessfully
        )
        successVC.onDone = completion
        return successVC
    }
}
