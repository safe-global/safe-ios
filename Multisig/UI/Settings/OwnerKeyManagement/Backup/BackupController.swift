//
//  BackupController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class BackupController: UINavigationController, UIAdaptivePresentationControllerDelegate {
    
    private var seedPhrase: String!
    
    private lazy var privateKey: PrivateKey = {
        try! PrivateKey(mnemonic: seedPhrase, pathIndex: 0)
    }()
    
    var onComplete: (() -> Void)?
    var onCancel: (() -> Void)?
    
    convenience init(showIntro: Bool, seedPhrase: String) {
        self.init()
        self.seedPhrase = seedPhrase
        let rootVC = showIntro ? createBackupIntro() : createBackupSeedPhrase()
        ViewControllerFactory.addCloseButton(rootVC)
        viewControllers = [rootVC]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationController?.delegate = self
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onCancel?()
    }

    func createBackupIntro() -> UIViewController {
        let backupVC = BackupIntroViewController()
        backupVC.backupCompletion = { [unowned self] startBackup in
            if startBackup {
                showBackupSeedPhrase()
            } else {
                onCancel?()
            }
        }
        return backupVC
    }

    func createBackupSeedPhrase() -> UIViewController {
        let backupVC = BackupSeedPhraseViewController()
        backupVC.seedPhrase = privateKey.mnemonic.map { $0.split(separator: " ").map(String.init) }!
        backupVC.onContinue = { [unowned self] in
            showVerifySeedPhrase()
        }
        return backupVC
    }
    
    func showBackupSeedPhrase() {
        let backupVC = createBackupSeedPhrase()
        show(backupVC, sender: self)
    }

    func showVerifySeedPhrase() {
        let verifyVC = VerifyPhraseViewController()
        verifyVC.phrase = privateKey.mnemonic.map { $0.split(separator: " ").map(String.init) } ?? []
        verifyVC.completion = { [unowned self] in
            updateKey()
            showBackupSuccess()
        }
        show(verifyVC, sender: self)
    }

    func showBackupSuccess() {
        Tracker.trackEvent(.backupCreatedSuccessfully)
        let successVC = SuccessViewController(
            titleText: "Your key is backed up!",
            bodyText: "If you lose your phone, you can recover this key with the seed phrase you just backed up.",
            primaryAction: "OK, great",
            secondaryAction: nil,
            trackingEvent: nil
        )
        successVC.onDone = { [unowned self] _ in
            self.dismiss(animated: true)
            onComplete?()
        }
        show(successVC, sender: self)
    }
    
    private func updateKey() {
        let keyItem = try? KeyInfo.firstKey(address: privateKey.address)
        keyItem?.backedup = true
        keyItem?.save()
        NotificationCenter.default.post(name: .ownerKeyUpdated, object: nil)
    }
}

// Rationale for design decisions about UI navigation between screens:
//
// I want view controllers to be usable in different contexts --> isolate them
// I want to have controller creation with parameters in different flows --> have a factory
// I want the whole flow to be defined in one space --> create an object for that
// I want the flow to be integratable into existing navigation stack --> pass the navigation controller to work with
// I want the flow to be stand-alone when opened from different places in the app --> create a navigation controller for the standalone case
// I want to have variations in the flows based on where it should be opened or based on the passed in parameters --> sub-class or enum. If more variations can be added in the future, then it is better to subclass

// Base variation for suggesting backup after generating a key:
//
// existing navigation -> intro -> seed -> verify -> success -> completed
//                              \
//                               -> canceled
//
// Another variation for a standalone backup flow:
//
// modal -> passcode -> seed -> verify -> success -> completed
//                    \
//                     -> canceled
class BackupFlow {
    var mnemonic: String
    var navigationController: UINavigationController
    var factory: BackupFlowFactory
    var completion: (_ success: Bool) -> Void

    init(mnemonic: String, navigationController: UINavigationController, factory: BackupFlowFactory = BackupFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.mnemonic = mnemonic
        self.navigationController = navigationController
        self.factory = factory
        self.completion = completion
    }

    init(mnemonic: String, factory: BackupFlowFactory = BackupFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.mnemonic = mnemonic
        self.factory = factory
        self.completion = completion
        self.navigationController = factory.navigation()
    }

    func start() {
        if let nav = navigationController as? CancellableNavigationController {
            nav.onCancel = { [unowned self] in
                stop(success: false)
            }

            seed()
        } else {
            intro()
        }
    }

    func intro() {
        let intro = factory.intro { [unowned self] shouldStartBackup in
            if shouldStartBackup {
                seed()
            } else {
                stop(success: false)
            }
        }
        // TODO: this is only for the embedded flow
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

    // TODO: perhaps move it to a business logic
    func updateKey() {
        guard let privateKey = (try? PrivateKey(mnemonic: mnemonic, pathIndex: 0)) else { return }
        let keyItem = try? KeyInfo.firstKey(address: privateKey.address)
        keyItem?.backedup = true
        keyItem?.save()
        NotificationCenter.default.post(name: .ownerKeyUpdated, object: nil)
    }

    func success() {
        let success = factory.success { [unowned self] didTapPrimary in
            stop(success: true)
        }
        show(success)
    }

    func stop(success: Bool) {
        completion(success)
    }

    func show(_ vc: UIViewController) {
        navigationController.show(vc, sender: navigationController)
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

    func navigation() -> CancellableNavigationController {
        let nav = CancellableNavigationController()
        return nav
    }
}

class CancellableNavigationController: UINavigationController, UIAdaptivePresentationControllerDelegate {

    var onCancel: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationController?.delegate = self
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onCancel?()
    }
}
