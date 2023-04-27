//
//  BackupController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Flow for backing up a seed phrase.
///
/// Expected to be embedded into a `GenerateKeyFlow`.
///
/// Screen sequence:
///
/// 1. Intro
/// 2. Show Seed
/// 3. Verify Seed
/// 4. Success
class BackupFlow: UIFlow {
    var mnemonic: String
    var factory: BackupFlowFactory = BackupFlowFactory()

    init(mnemonic: String, completion: @escaping (_ success: Bool) -> Void) {
        self.mnemonic = mnemonic
        super.init(completion: completion)
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

/// Flow to back up a seed phrase in a modal way.
///
/// Expected to be opened as a separate flow, modally.
///
/// Screen sequence:
///
/// 1. Enter Passcode
/// 2. Show Seed (in superclass)
/// 3. Verify Seed (in superclass)
/// 4. Success (in superclass)
class ModalBackupFlow: BackupFlow {

    override func start() {
        if AppSettings.securityLockEnabled {
            seed()
        } else {
            passcode()
        }
    }

    func passcode() {
        let factory = PasscodeFlowFactory()
        let enterVC = factory.enter(biometry: false, options: []) { [unowned self] result in
            if case EnterPasscodeViewController.Result.success(_) = result {
                seed()
            } else {
                stop(success: false)
            }
        }
        
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
