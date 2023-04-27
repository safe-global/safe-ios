//
//  AuthenticationController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/17/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftAccessPolicy

import LocalAuthentication

class AuthenticationController {

    private let accessService: AccessService

    #if DEBUG
    var test_override_isBiometrySupported: Bool?
    #endif

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

    /// This method will derive a key from the passcode, hash it, and store
    /// it in the Keychain.
    ///
    /// - Parameter plaintextPasscode: unsecured, "as-is" passcode
    func createPasscode(plaintextPasscode: String) throws {
        for user in accessService.userRepository.users() {
            accessService.userRepository.delete(userID: user.id)
        }
        let password = App.shared.securityCenter.derivedKey(from: plaintextPasscode)
        try accessService.registerUser(password: password)
        AppSettings.passcodeWasSetAtLeastOnce = true

        AppSettings.passcodeOptions = [.useForLogin, .useForConfirmation]

        NotificationCenter.default.post(name: .passcodeCreated, object: nil)

        Tracker.setPasscodeIsSet(to: true)
        Tracker.trackEvent(.userPasscodeEnabled)
    }

    /// Changes the passcode to a new value.
    /// - Parameter newPasscodeInPlaintext: unsecured "as-is" passcode
    func changePasscode(newPasscodeInPlaintext: String) throws {
        guard let user = user else { return }
        let password = App.shared.securityCenter.derivedKey(from: newPasscodeInPlaintext)
        try accessService.updateUserPassword(userID: user.id, password: password)
    }

    /// Checks if the passcode correct. In case passcode is not set, returns false.
    /// - Parameter plaintextPasscode: unsecured "as-is" passcode
    /// - Returns: true if passcode correct, false otherwise
    func  isPasscodeCorrect(plaintextPasscode: String) throws -> Bool {
        guard let user = user else { return false }
        let password = App.shared.securityCenter.derivedKey(from: plaintextPasscode)
        let oldPassword = App.shared.securityCenter.derivedKey(from: plaintextPasscode, useOldSalt: true)
        return try accessService.verifyPassword(userID: user.id, password: password) ||
                    accessService.verifyPassword(userID: user.id , password: oldPassword)
    }

    /// Deletes the stored passcode. If passcode not set, this operation
    /// does not have any effect.
    func deletePasscode(authenticate: Bool = true, trackingEvent: TrackingEvent = .userPasscodeDisabled) {
        if AppConfiguration.FeatureToggles.securityCenter {
            App.shared.securityCenter.disableSecurityLock (authenticate: authenticate) { error in
                if let error = error {
                    LogService.shared.error("Failed to delete passcode: \(error)")
                } else {
                    NotificationCenter.default.post(name: .passcodeDeleted, object: nil)

                    Tracker.setPasscodeIsSet(to: false)
                    Tracker.trackEvent(trackingEvent)

                    App.shared.snackbar.show(message: "Passcode disabled")
                }
            }
        } else {
            do {
                guard let user = user else { return }
                try accessService.deleteUser(userID: user.id)

                NotificationCenter.default.post(name: .passcodeDeleted, object: nil)

                Tracker.setPasscodeIsSet(to: false)
                Tracker.trackEvent(trackingEvent)

                App.shared.snackbar.show(message: "Passcode disabled")
            } catch {
                let uiError = GSError.error(
                    description: "Failed to delete passcode",
                    error: GSError.GenericPasscodeError(reason: error.localizedDescription))
                App.shared.snackbar.show(error: uiError)
            }
        }
    }

    func deleteAllData() throws {
        try Safe.removeAll()
        try OwnerKeyController.deleteAllKeys(showingMessage: false)
        deletePasscode(authenticate: false, trackingEvent: .userPasscodeReset)
        App.shared.snackbar.show(message: "All data removed from this app")
    }

    func migrateFromPasscodeV1() {
        // if passcode is set but all options are 0, then we have inconsistent settings.
        // to restore, we will enable passcode entry for confirmations, as this is the expected
        // behavior in the v1.
        guard isPasscodeSetAndAvailable && AppSettings.passcodeOptions.isEmpty else { return }
        AppSettings.passcodeOptions = .useForConfirmation
    }

    /// Returns saved user, if any
    private var user: User? {
        try? fetchUser()
    }

    func fetchUser() throws -> User? {
        try AppUser.all().first?.user()
    }

    var isPasscodeSetAndAvailable: Bool {
        if AppConfiguration.FeatureToggles.securityCenter {
            return App.shared.securityCenter.securityLockEnabled
        } else {
            guard let user = (try? fetchUser()) else {
                // passcode not available
                return false
            }
            return !user.encryptedPassword.isEmpty
        }
    }


    // MARK: - Biometry

    /// Is device hardware supports the biometry
    var isBiometricsSupported: Bool {
        #if DEBUG
        if let testResult = test_override_isBiometrySupported {
            return testResult
        }
        #endif

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

    func activateBiometrics(lockMethod: LockMethod? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        evaluate(policy: .deviceOwnerAuthenticationWithBiometrics,
                 reason: "Enable login with biometrics",
                 showsFallback: false,
                 errorConverter: GSError.BiometryActivationError.init(underlyingError:)) { result in

            switch result {
            case .success:
                if AppConfiguration.FeatureToggles.securityCenter {
                    AppSettings.securityLockMethod = lockMethod == nil ? .userPresence : lockMethod!
                } else {
                    AppSettings.passcodeOptions.insert(.useBiometry)
                }

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
            try appUser.update(with: user)
            appUser.save()
        } catch {
            LogService.shared.error("Failed to save user: \(error)")
        }
    }

    func delete(userID: UUID) {
        do {
            if let appUser = try AppUser.user(id: userID) {
                appUser.delete()
            }
        } catch {
            LogService.shared.error("Failed to delete user: \(error)")
        }
    }

    func user(userID: UUID) -> User? {
        do {
            let appUser = try AppUser.user(id: userID)
            return try appUser?.user()
        } catch {
            LogService.shared.error("Failed to load user: \(error)")
            return nil
        }
    }

    func users() -> [User] {
        do {
            let appUsers = try AppUser.all()
            return try appUsers.map { try $0.user() }
        } catch {
            LogService.shared.error("Failed to get users: \(error)")
            return []
        }
    }
}

extension AppUser {
    func update(with user: User) throws {
        assert(id == user.id)
        // here, the updating might fail because keychain is not accessible.
        try setEncryptedPassword(user.encryptedPassword)
        sessionRenewedAt = user.sessionRenewedAt
        failedAuthAttempts = Int64(user.failedAuthAttempts)
        accessBlockedAt = user.accessBlockedAt
    }

    func user() throws -> User {
        // here, getting password might fail if keychain is not accessible
        let passwordOrNil = try encryptedPassword()
        guard let id = id, let password = passwordOrNil else {
            throw GSError.DatabaseError(reason: "User id or password unavailable")
        }
        var result = User(userID: id, encryptedPassword: password)
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
