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

        let firstQuestion = verifyVC.questions[0]
        let firstWrongAnswer = firstQuestion.choices.firstIndex(where: { $0 != firstQuestion.correctAnswer})!
        verifyVC.didSelectWord(at: firstWrongAnswer)
        XCTAssertEqual(verifyVC.state, .incorrect, "wrong state")
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

        let firstQuestion = verifyVC.questions[0]
        let firstCorrectAnswer = firstQuestion.choices.firstIndex(where: { $0 == firstQuestion.correctAnswer})!
        verifyVC.didSelectWord(at: firstCorrectAnswer)
        XCTAssertEqual(verifyVC.state, .correct, "wrong state")

        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let secondQuestion = verifyVC.questions[1]
        let secondWrongAnswer = secondQuestion.choices.firstIndex(where: { $0 != secondQuestion.correctAnswer})!
        verifyVC.didSelectWord(at: secondWrongAnswer)
        XCTAssertEqual(verifyVC.state, .incorrect, "wrong state")
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

        let firstQuestion = verifyVC.questions[0]
        let firstCorrectAnswer = firstQuestion.choices.firstIndex(where: { $0 == firstQuestion.correctAnswer})!
        verifyVC.didSelectWord(at: firstCorrectAnswer)
        XCTAssertEqual(verifyVC.state, .correct, "wrong state")

        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let secondQuestion = verifyVC.questions[1]
        let secondCorrectAnswer = secondQuestion.choices.firstIndex(where: { $0 == secondQuestion.correctAnswer})!
        verifyVC.didSelectWord(at: secondCorrectAnswer)
        XCTAssertEqual(verifyVC.state, .correct, "wrong state")

        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let thirdQuestion = verifyVC.questions[2]
        let thirdWrongAnswer = thirdQuestion.choices.firstIndex(where: { $0 != thirdQuestion.correctAnswer})!
        verifyVC.didSelectWord(at: thirdWrongAnswer)
        XCTAssertEqual(verifyVC.state, .incorrect, "wrong state")
    }

    func test_verifySeedSuccess() {

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        flow.verify()
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let verifyVC = topPresentedController() as! VerifyPhraseViewController
        XCTAssertEqual(verifyVC.state, .question, "wrong state")

        let firstQuestion = verifyVC.questions[0]
        let firstCorrectAnswer = firstQuestion.choices.firstIndex(where: { $0 == firstQuestion.correctAnswer})!
        verifyVC.didSelectWord(at: firstCorrectAnswer)
        XCTAssertEqual(verifyVC.state, .correct, "wrong state")

        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let secondQuestion = verifyVC.questions[1]
        let secondCorrectAnswer = secondQuestion.choices.firstIndex(where: { $0 == secondQuestion.correctAnswer})!
        verifyVC.didSelectWord(at: secondCorrectAnswer)
        XCTAssertEqual(verifyVC.state, .correct, "wrong state")

        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let thirdQuestion = verifyVC.questions[2]
        let thirdCorrectAnswer = thirdQuestion.choices.firstIndex(where: { $0 == thirdQuestion.correctAnswer})!
        verifyVC.didSelectWord(at: thirdCorrectAnswer)
        XCTAssertEqual(verifyVC.state, .correct, "wrong state")

        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        XCTAssertEqual(verifyVC.state, .completed, "wrong state")
    }

    func test_updateKey() {

        let privateKey = try! PrivateKey(mnemonic: mnemonic, pathIndex: 0)
        do {
            try KeyInfo.import(address: privateKey.address, name: "key", privateKey: privateKey)
        } catch {
            XCTFail()
        }

        let flow = BackupFlow(mnemonic: mnemonic) { success in }
        flow.modal(from: presenterVC)
        flow.updateKey()
        // wait for presentation animation to complete
        wait(timeout: waitingTime)

        let keyItem = try! KeyInfo.firstKey(address: privateKey.address)!

        XCTAssertTrue(keyItem.backedup, "key not backed up")
    }
}
