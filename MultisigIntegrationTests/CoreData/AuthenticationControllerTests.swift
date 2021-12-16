//
//  AuthenticationControllerTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 2/18/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class AuthenticationControllerTests: CoreDataTestCase {
    let mockStore = MockSecureStore()
    let passcode = "1234567890"
    let emptyPasscode = ""
    let invalidPasscode = "asdfqwerty"
    let newPasscode = "zxcvnm,."
    let changedPasscode = "opcv71j"

    override func setUpWithError() throws {
        try super.setUpWithError()
        App.shared.keychainService = mockStore
    }

    func testExample() throws {
        let auth = App.shared.auth

        // verify that peasscode is not set
        XCTAssertFalse(auth.isPasscodeSetAndAvailable)
        XCTAssertFalse(AppSettings.passcodeWasSetAtLeastOnce)
        XCTAssertFalse(try auth.isPasscodeCorrect(plaintextPasscode: passcode))

        // delete should have no consequences when passcode not set
        try auth.deletePasscode()
        XCTAssertFalse(auth.isPasscodeSetAndAvailable)

        // create will set the passcode
        try auth.createPasscode(plaintextPasscode: passcode)
        XCTAssertTrue(auth.isPasscodeSetAndAvailable)
        XCTAssertTrue(AppSettings.passcodeWasSetAtLeastOnce)

        // check if valid passcode accepted
        XCTAssertTrue(try auth.isPasscodeCorrect(plaintextPasscode: passcode))
        XCTAssertFalse(try auth.isPasscodeCorrect(plaintextPasscode: emptyPasscode))
        XCTAssertFalse(try auth.isPasscodeCorrect(plaintextPasscode: invalidPasscode))

        // empty passcode is also accepted
        try auth.createPasscode(plaintextPasscode: emptyPasscode)

        // repeated creation of passcode will override previous passcode
        try auth.createPasscode(plaintextPasscode: newPasscode)
        XCTAssertTrue(try auth.isPasscodeCorrect(plaintextPasscode: newPasscode))
        XCTAssertFalse(try auth.isPasscodeCorrect(plaintextPasscode: passcode))

        // change to another passcode
        try auth.changePasscode(newPasscodeInPlaintext: changedPasscode)
        XCTAssertTrue(try auth.isPasscodeCorrect(plaintextPasscode: changedPasscode))
        XCTAssertFalse(try auth.isPasscodeCorrect(plaintextPasscode: newPasscode))

        // delete will remove the passcode
        try auth.deletePasscode()
        XCTAssertFalse(auth.isPasscodeSetAndAvailable)
        XCTAssertTrue(AppSettings.passcodeWasSetAtLeastOnce)

        XCTAssertFalse(try auth.isPasscodeCorrect(plaintextPasscode: changedPasscode))
    }

}
