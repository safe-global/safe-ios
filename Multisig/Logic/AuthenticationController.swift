//
//  AuthenticationController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/17/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftAccessPolicy
import CommonCrypto
import LocalAuthentication

class AuthenticationController {

    private let accessService: AccessService

    init() {
        accessService = AccessService(
            accessPolicy: AccessPolicy(
                sessionDuration: .greatestFiniteMagnitude,
                maxFailedAttempts: .max,
                blockDuration: 0),
            biometryReason: BiometryReason(
                touchIDActivation: "Enable using Touch ID",
                touchIDAuth: "Unlock using Touch ID",
                faceIDActivation: "Enable using Face ID",
                faceIDAuth: "Unlock using Face ID",
                unrecognizedBiometryType: "Unrecognized Biometry type"))
        accessService.userRepository = AuthUserRepository()
    }

    /// Returns true if the passcode is set up, false otherwise
    var isPasscodeSet: Bool {
        guard let user = user else { return false }
        return !user.encryptedPassword.isEmpty
    }

    /// This method will derive a key from the passcode, hash it, and store
    /// it in the Keychain.
    ///
    /// - Parameter plaintextPasscode: unsecured, "as-is" passcode
    func createPasscode(plaintextPasscode: String) throws {
        for user in accessService.userRepository.users() {
            accessService.userRepository.delete(userID: user.id)
        }
        let password = derivedKey(from: plaintextPasscode)
        try accessService.registerUser(password: password)
        AppSettings.passcodeWasSetAtLeastOnce = true

        AppSettings.passcodeOptions = [.useForLogin, .useForConfirmation]

        NotificationCenter.default.post(name: .passcodeCreated, object: nil)

        Tracker.shared.setPasscodeIsSet(to: true)
        Tracker.shared.track(event: TrackingEvent.userPasscodeEnabled)
    }

    /// Changes the passcode to a new value.
    /// - Parameter newPasscodeInPlaintext: unsecured "as-is" passcode
    func changePasscode(newPasscodeInPlaintext: String) throws {
        guard let user = user else { return }
        let password = derivedKey(from: newPasscodeInPlaintext)
        try accessService.updateUserPassword(userID: user.id, password: password)
    }

    /// Checks if the passcode correct. In case passcode is not set, returns false.
    /// - Parameter plaintextPasscode: unsecured "as-is" passcode
    /// - Returns: true if passcode correct, false otherwise
    func isPasscodeCorrect(plaintextPasscode: String) throws -> Bool {
        guard let user = user else { return false }
        let password = derivedKey(from: plaintextPasscode)
        return try accessService.verifyPassword(userID: user.id, password: password)
    }

    /// Deletes the stored passcode. If passcode not set, this operation
    /// does not have any effect.
    func deletePasscode(trackingEvent: TrackingEvent = .userPasscodeDisabled) throws {
        guard let user = user else { return }
        try accessService.deleteUser(userID: user.id)

        NotificationCenter.default.post(name: .passcodeDeleted, object: nil)

        Tracker.shared.setPasscodeIsSet(to: false)
        Tracker.shared.track(event: trackingEvent)
    }

    func deleteAllData() throws {
        try PrivateKeyController.deleteAllKeys(showingMessage: false)
        try Safe.removeAll()
        try deletePasscode(trackingEvent: .userPasscodeReset)
        App.shared.snackbar.show(message: "All data removed from this app")
    }

    func migrateFromPasscodeV1() {
        // if passcode is set but all options are 0, then we have inconsistent settings.
        // to restore, we will enable passcode entry for confirmations, as this is the expected
        // behavior in the v1.
        guard isPasscodeSet && AppSettings.passcodeOptions.isEmpty else { return }
        AppSettings.passcodeOptions = .useForConfirmation
    }

    /// Returns saved user, if any
    private var user: User? {
        try? AppUser.all().first?.user()
    }

    private func derivedKey(from plaintext: String) -> String {
        let salt = "Gnosis Safe Multisig Passcode Salt"
        var derivedKey = [UInt8](repeating: 0, count: 256 / 8)
        let result = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            plaintext,
            plaintext.lengthOfBytes(using: .utf8),
            salt,
            salt.lengthOfBytes(using: .utf8),
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            100_000,
            &derivedKey,
            derivedKey.count)
        guard result == kCCSuccess else {
            LogService.shared.error("Failed to derive key", error: "Failed to derive a key: \(result)")
            return plaintext
        }
        return Data(derivedKey).toHexString()
    }


    // MARK: - Biometry

    /// Is device hardware supports the biometry
    var isBiometricsSupported: Bool {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .touchID, .faceID:
            return true
        case .none:
            return false
        @unknown default:
            return false
        }
    }

    var isBiometryPossible: Bool {
        guard let user = user else { return false }
        return (try? accessService.isAuthenticationMethodPossible(userID: user.id, method: .biometry)) ?? false
    }

    var isFaceID: Bool {
        return (try? accessService.biometryService.biometryType()) == .faceID
    }

    func activateBiometry() throws -> Bool {
        guard let user = user else { return false }
        return try accessService.requestBiometryAccess(userID: user.id)
    }

    func authenticateWithBiometry() -> Bool {
        guard let user = user else { return false }
        let status = (try? accessService.authenticateUser(userID: user.id, request: .biometry)) ?? .notAuthenticated
        return status == .authenticated
    }
}

class AuthUserRepository: UserRepository {

    func save(user: User) {
        do {
            let appUser = try AppUser.user(id: user.id) ?? AppUser.newUser(id: user.id)
            appUser.update(with: user)
            appUser.save()
        } catch {
            LogService.shared.error("Failed to save user", error: error)
        }
    }

    func delete(userID: UUID) {
        do {
            if let appUser = try AppUser.user(id: userID) {
                appUser.delete()
            }
        } catch {
            LogService.shared.error("Failed to save user", error: error)
        }
    }

    func user(userID: UUID) -> User? {
        do {
            let appUser = try AppUser.user(id: userID)
            return appUser?.user()
        } catch {
            LogService.shared.error("Failed to save user", error: error)
            return nil
        }
    }

    func users() -> [User] {
        do {
            let appUsers = try AppUser.all()
            return appUsers.map { $0.user() }
        } catch {
            LogService.shared.error("Failed to save user", error: error)
            return []
        }
    }
}

extension AppUser {
    func update(with user: User) {
        assert(id == user.id)
        encryptedPassword = user.encryptedPassword
        sessionRenewedAt = user.sessionRenewedAt
        failedAuthAttempts = Int64(user.failedAuthAttempts)
        accessBlockedAt = user.accessBlockedAt
    }

    func user() -> User {
        var result = User(userID: id!, encryptedPassword: encryptedPassword)
        result.sessionRenewedAt = sessionRenewedAt
        result.failedAuthAttempts = Int(failedAuthAttempts)
        result.accessBlockedAt = accessBlockedAt
        return result
    }
}


extension AccessServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .userAlreadyExists:
            return "The passcode already set."
        case .userDoesNotExist:
            return "The passcode is not set."
        }
    }
}
