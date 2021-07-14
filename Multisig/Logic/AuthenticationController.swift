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

        AppSettings.passcodeOptions = [.useForLogin, .useForConfirmation, .useForExportingKeys]

        NotificationCenter.default.post(name: .passcodeCreated, object: nil)

        Tracker.setPasscodeIsSet(to: true)
        Tracker.trackEvent(.userPasscodeEnabled)
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

        Tracker.setPasscodeIsSet(to: false)
        Tracker.trackEvent(trackingEvent)
    }

    func deleteAllData() throws {
        try OwnerKeyController.deleteAllKeys(showingMessage: false)
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

    func migrateUsePasscodeForExportingKey() {
        guard !AppSettings.usePasscodeForExportingKeyMigrated else { return }
        if isPasscodeSet {
            AppSettings.passcodeOptions.insert(.useForExportingKeys)
        }

        AppSettings.usePasscodeForExportingKeyMigrated = true
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
        switch context.evaluatedBiometryType {
        case .touchID, .faceID:
            return true
        case .none:
            return false
        @unknown default:
            return false
        }
    }

    var isBiometryActivationPossible: Bool {
        canEvaluate(policy: .deviceOwnerAuthenticationWithBiometrics)
    }

    var isBiometryAuthenticationPossible: Bool {
        canEvaluate(policy: .deviceOwnerAuthentication)
    }

    var isFaceID: Bool {
        let context = LAContext()
        return context.evaluatedBiometryType == .faceID
    }

    func activateBiometrics(completion: @escaping (Result<Void, Error>) -> Void) {
        evaluate(policy: .deviceOwnerAuthenticationWithBiometrics,
                 reason: "Enable login with biometrics",
                 showsFallback: false,
                 errorConverter: GSError.BiometryActivationError.init(underlyingError:)) { result in

            switch result {
            case .success:
                AppSettings.passcodeOptions.insert(.useBiometry)
                NotificationCenter.default.post(name: .biometricsActivated, object: nil)
                App.shared.snackbar.show(message: "Biometrics activated.")
                completion(.success(()))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func authenticateWithBiometrics(completion: @escaping (Result<Void, Error>) -> Void) {
        evaluate(policy: .deviceOwnerAuthentication,
                 reason: "Login with biometrics",
                 showsFallback: true,
                 errorConverter: GSError.BiometryAuthenticationError.init(underlyingError:),
                 completion: completion)
    }

    private func evaluate(
        policy: LAPolicy,
        reason: String,
        showsFallback: Bool,
        errorConverter: @escaping (_ error: Error) -> DetailedLocalizedError,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let context = LAContext()
        context.localizedFallbackTitle = showsFallback ? nil : ""

        let canEvaluate = context.canEvaluate(policy: policy)

        switch canEvaluate {

        case .failure(let error):
            let gsError = errorConverter(error)
            App.shared.snackbar.show(error: gsError)
            completion(.failure(gsError))

        case .success:
            context.evaluate(policy: policy, reason: reason) { result in

                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        let gsError = errorConverter(error)
                        App.shared.snackbar.show(error: gsError)
                        completion(.failure(gsError))
                    }
                }
            }
        }
    }

    private func canEvaluate(policy: LAPolicy) -> Bool {
        guard user != nil else { return false }
        let context = LAContext()
        let result = context.canEvaluate(policy: policy)
        switch result {
        case .success:
            return true
        case .failure(_):
            return false
        }
    }

}

extension LAContext {

    var evaluatedBiometryType: LABiometryType {
        _ = canEvaluate(policy: .deviceOwnerAuthentication)
        return biometryType
    }

    func canEvaluate(policy: LAPolicy) -> Result<Void, Error> {
        var error: NSError!
        let success = canEvaluatePolicy(policy, error: &error)
        if success {
            return .success(())
        } else {
            return .failure(error as Error)
        }
    }

    func evaluate(policy: LAPolicy, reason: String, completion: @escaping (_ result: Result<Void, Error>) -> Void) {
        evaluatePolicy(policy, localizedReason: reason) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(error!))
                }
            }
        }
    }
}
extension LABiometryType {
    var displayValue: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        @unknown default:
            return "Unknown"
        }
    }
}

extension LAPolicy {
    var displayValue: String {
        switch self {
        case .deviceOwnerAuthenticationWithBiometrics:
            return "Biometry"
        case .deviceOwnerAuthentication:
            return "Biometry or Device Passcode"
        @unknown default:
            return "unknown"
        }
    }
}


class AuthUserRepository: UserRepository {

    func save(user: User) {
        do {
            let appUser = try AppUser.user(id: user.id) ?? AppUser.newUser(id: user.id)
            appUser.update(with: user)
            AppSettings.usePasscodeForExportingKeyMigrated = true
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
