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
        flow.seed()
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let topScreen = topPresentedController()
        XCTAssertTrue(topScreen is BackupSeedPhraseViewController, "not a backup seed phrase screen")
    }

    func test_verifySeedContinue() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        flow.verify()
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let topScreen = topPresentedController()
        XCTAssertTrue(topScreen is VerifyPhraseViewController, "not a verify seed phrase screen")
    }

    // scenario 1: first word is incorrect
    func test_verifySeedFailure_firstWord() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        flow.verify()
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let verifyVC = topPresentedController() as! VerifyPhraseViewController
        XCTAssertEqual(verifyVC.state, .question, "wrong state")

        verifyVC.verifyAnswerSelection(questionIndex: 0, correct: false)
    }

    // scenario 2: second word is incorrect
    func test_verifySeedFailure_secondWord() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        flow.verify()
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let verifyVC = topPresentedController() as! VerifyPhraseViewController
        XCTAssertEqual(verifyVC.state, .question, "wrong state")

        verifyVC.verifyAnswerSelection(questionIndex: 0, correct: true)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        verifyVC.verifyAnswerSelection(questionIndex: 1, correct: false)
    }

    // scenario 3: third word is incorrect
    func test_verifySeedFailure_thirdWord() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        flow.verify()
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let verifyVC = topPresentedController() as! VerifyPhraseViewController
        XCTAssertEqual(verifyVC.state, .question, "wrong state")

        verifyVC.verifyAnswerSelection(questionIndex: 0, correct: true)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        verifyVC.verifyAnswerSelection(questionIndex: 1, correct: true)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        verifyVC.verifyAnswerSelection(questionIndex: 2, correct: false)
    }

    func test_verifySeedSuccess() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        flow.verify()
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let verifyVC = topPresentedController() as! VerifyPhraseViewController
        XCTAssertEqual(verifyVC.state, .question, "wrong state")

        verifyVC.verifyAnswerSelection(questionIndex: 0, correct: true)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        verifyVC.verifyAnswerSelection(questionIndex: 1, correct: true)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        verifyVC.verifyAnswerSelection(questionIndex: 2, correct: true)
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        XCTAssertEqual(verifyVC.state, .completed, "wrong state")
    }

    func test_updateKey() throws {

        let privateKey = try PrivateKey(mnemonic: mnemonic, pathIndex: 0)
        try KeyInfo.import(address: privateKey.address, name: "key", privateKey: privateKey, type: .deviceGenerated)

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        flow.updateKey()
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let keyItem = try KeyInfo.firstKey(address: privateKey.address)!

        XCTAssertTrue(keyItem.backedup, "key not backed up")
    }
}

extension VerifyPhraseViewController {

    func verifyAnswerSelection(questionIndex: Int, correct: Bool) {

        let question = questions[questionIndex]

        let answerIndex = question.choices.firstIndex(where: {
            var result: Bool!
            if correct {
                result = $0 == question.correctAnswer
            } else {
                result = $0 != question.correctAnswer
            }
            return result
        })!

        didSelectWord(at: answerIndex)

        if correct {
            XCTAssertEqual(state, .correct, "wrong state")
        } else {
            XCTAssertEqual(state, .incorrect, "wrong state")
        }
    }
}
