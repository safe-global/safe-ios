//
//  BackupFlowTests.swift
//  MultisigIntegrationTests
//
//  Created by Vitaly on 15.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class BackupFlowTests: UIIntegrationTestCase {

    var waitingTime: TimeInterval = 1
    let mnemonic = "obvious cart elephant coach move gain alpha mask size seed few powder"
    

    func test_showsIntro() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let topScreen = topPresentedController()
        XCTAssertTrue(topScreen is BackupIntroViewController, "not a backup intro screen")
    }

    func test_cancelsBackup() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let backupIntroVC = topPresentedController() as! BackupIntroViewController
        backupIntroVC.backupCompletion(false)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let topScreen = presenterVC.presentedViewController
        XCTAssertNil(topScreen, "flow not dismissed")
    }

    func test_startsBackup() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let backupIntroVC = topPresentedController() as! BackupIntroViewController
        backupIntroVC.backupCompletion(true)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let topScreen = topPresentedController()
        XCTAssertTrue(topScreen is BackupSeedPhraseViewController, "not a backup seed phrase screen")
    }

    func test_verifySeedContinue() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        wait(timeout: waitingTime)

        let backupIntroVC = topPresentedController() as! BackupIntroViewController
        backupIntroVC.backupCompletion(true)
        wait(timeout: waitingTime)

        let seedVC = topPresentedController() as! BackupSeedPhraseViewController
        seedVC.onContinue!()
        wait(timeout: waitingTime)

        let topScreen = topPresentedController()
        XCTAssertTrue(topScreen is VerifyPhraseViewController, "not a verify seed phrase screen")
    }

    func test_verifySeedFailure() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        wait(timeout: waitingTime)

        let backupIntroVC = topPresentedController() as! BackupIntroViewController
        backupIntroVC.backupCompletion(true)
        wait(timeout: waitingTime)

        let seedVC = topPresentedController() as! BackupSeedPhraseViewController
        seedVC.onContinue!()
        wait(timeout: waitingTime)

        let verifyVC = topPresentedController() as! VerifyPhraseViewController
        XCTAssertEqual(verifyVC.state, .question, "wrong state")

        //TODO: click through questions selecting wrong words
        // scenario 1: first word is incorrect
        // scenario 2: second word is incorrect
        // scenario 3: third word is incorrect
        
//        verifyVC.moveToNext()
//        XCTAssertEqual(verifyVC.state, .question, "wrong state")

    }

    func test_verifySeedSuccess() {
        //TODO: click through questions selecting correct words
    }
}
