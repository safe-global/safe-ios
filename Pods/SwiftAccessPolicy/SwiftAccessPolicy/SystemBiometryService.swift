//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import LocalAuthentication

public enum BiometryServiceError: Error {
    case canNotEvaluatePolicy(Error)
    case authenticationCanceled
}

public class SystemBiometryService: BiometryService {
    private let contextProvider: () -> LAContext
    private var context: LAContext
    public private(set) var biometryReason: BiometryReason

    /// Creates new biometric service with LAContext provider.
    /// Autoclosure here means that LAContext will be fetched every time from the closure.
    /// By default, it will be created anew when contextProvider() is called.
    /// We have to re-create LAContext so that previous biometry authentication is not reused by the system.
    /// - Parameters:
    ///   - biometryReason: BiometryReason
    ///   - localAuthenticationContext: closure that returns LAContext
    public init(biometryReason: BiometryReason,
                localAuthenticationContext: @escaping @autoclosure () -> LAContext = LAContext()) {
        self.biometryReason = biometryReason
        self.contextProvider = localAuthenticationContext
        context = contextProvider()
    }

    public func biometryType() throws -> BiometryType {
        guard try isBiometryAvailable() else { return .none }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .none: return .none
        @unknown default: return .none
        }
    }

    public func activate() throws -> Bool {
        var reason: String
        switch try biometryType() {
        case .touchID:
            reason = biometryReason.touchIDActivation
        case .faceID:
            reason = biometryReason.faceIDActivation
        case .none:
            reason = biometryReason.unrecognizedBiometryType
        }
        return try requestBiometry(reason: reason)
    }

    public func authenticate() throws -> Bool {
        var reason: String
        switch try biometryType() {
        case .touchID:
            reason = biometryReason.touchIDAuth
        case .faceID:
            reason = biometryReason.faceIDAuth
        case .none:
            reason = biometryReason.unrecognizedBiometryType
        }
        return try requestBiometry(reason: reason)
    }

    @discardableResult
    private func requestBiometry(reason: String) throws -> Bool {
        guard try isBiometryAvailable() else { return false }
        var success: Bool = false
        var evaluationError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        context.evaluatePolicy(policy, localizedReason: reason) { result, errorOrNil in
            evaluationError = errorOrNil
            success = result
            semaphore.signal()
        }
        semaphore.wait()
        if let error = evaluationError {
            guard let laError = error as? LAError else { throw error }
            switch laError.code {
            case .authenticationFailed:
                return false
            case .userCancel,
                 .appCancel,
                 .systemCancel,
                 .userFallback,
                 .passcodeNotSet,
                 .biometryNotEnrolled,
                 .biometryNotAvailable,
                 .biometryLockout:
                throw BiometryServiceError.authenticationCanceled
            case .invalidContext,
                 .notInteractive:
                fallthrough
            default:
                throw BiometryServiceError.canNotEvaluatePolicy(error)
            }
        }
        return success
    }

    private func isBiometryAvailable() throws -> Bool {
        context = contextProvider()
        context.interactionNotAllowed = false
        var evaluationError: NSError?
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evaluationError)
        if let error = evaluationError {
            throw BiometryServiceError.canNotEvaluatePolicy(error)
        }
        return result
    }
}
