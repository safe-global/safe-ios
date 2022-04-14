//
//  BackupController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class BackupController: UINavigationController {
    
    private var seedPhrase: String!
    
    private lazy var privateKey: PrivateKey = {
        try! PrivateKey(mnemonic: seedPhrase, pathIndex: 0)
    }()
    
    var onComplete: (() -> Void)?
    var onCancel: (() -> Void)?
    
    
    convenience init(showIntro: Bool, seedPhrase: String) {
        self.init(namedClass: nil)
        self.seedPhrase = seedPhrase
        if showIntro {
            showBackupIntro()
        } else {
            showBackupSeedPhrase()
        }
    }

    func showBackupIntro() {
        let backupVC = BackupIntroViewController()
        backupVC.backupCompletion = { [unowned self] startBackup in
            if startBackup {
                showBackupSeedPhrase()
            } else {
                self.dismiss(animated: true)
                onCancel?()
            }
        }
        show(backupVC, sender: self)
    }
    
    func showBackupSeedPhrase() {
        let backupVC = BackupSeedPhraseViewController()
        backupVC.seedPhrase = privateKey.mnemonic.map { $0.split(separator: " ").map(String.init) }!
        backupVC.onContinue = { [unowned self] in
            showVerifySeedPhrase()
        }
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
        let successVC = SuccessViewController(
            titleText: "Your key is backed up!",
            bodyText: "If you lose your phone, you can recover this key with the seed phrase you just backed up.",
            doneTitle: "OK, great",
            trackingEvent: nil
        )
        successVC.onDone = { [unowned self] in
            self.dismiss(animated: true)
            onComplete?()
        }
        show(successVC, sender: self)
    }
    
    private func updateKey() {
        let keyItem = try? KeyInfo.firstKey(address: privateKey.address)
        keyItem?.backedup = true
        keyItem?.save()
    }
}
