//
//  AccessService.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CryptoKit

/// Access service policy configuration
public struct AccessPolicy {
    public let sessionDuration: TimeInterval
    public let maxFailedAttempts: Int
    public let blockDuration: TimeInterval

    public init(
        sessionDuration: TimeInterval,
        maxFailedAttempts: Int,
        blockDuration: TimeInterval) {
        self.sessionDuration = sessionDuration
        self.maxFailedAttempts = maxFailedAttempts
        self.blockDuration = blockDuration
    }
}

/// Valid authentication methods supported by the application
public struct AuthMethod: OptionSet {
    public let rawValue: Int

    public static let password = AuthMethod(rawValue: 1 << 0)
    public static let touchID = AuthMethod(rawValue: 1 << 1)
    public static let faceID = AuthMethod(rawValue: 1 << 2)

    public static let biometry: AuthMethod = [.touchID, .faceID]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// Represents authentication intent
public enum AuthRequest {
    case password(String)
    case biometry
}

/// Authentication status
/// For blocked status return the left blocking time interval
public enum AuthStatus: Equatable {
    case authenticated
    case notAuthenticated
    case blocked(TimeInterval)
}

public enum AccessServiceError: Error {
    case userAlreadyExists
    case userDoesNotExist
}

public class AccessService {
    public var accessPolicy: AccessPolicy
    public var userRepository: UserRepository
    public var biometryService: BiometryService

    public init(accessPolicy: AccessPolicy, biometryReason: BiometryReason) {
        self.accessPolicy = accessPolicy
        self.userRepository = InMemotyUserRepository()
        self.biometryService = SystemBiometryService(biometryReason: biometryReason)
    }

    // MARK: - Users management

    /// Registers user
    /// - Parameters:
    ///   - userID: unique user ID; default value is UUID()
    ///   - password: plain text password
    /// - Throws: AccessServiceError
    /// - Returns: registered user ID
    @discardableResult
    public func registerUser(userID: UUID = UUID(), password: String) throws -> UUID {
        if (try? user(id: userID)) != nil {
            throw AccessServiceError.userAlreadyExists
        }
        let user = User(userID: userID, encryptedPassword: encrypted(password))
        userRepository.save(user: user)
        return user.id
    }

    /// Requests system biometry
    /// - Parameter userID: unique user ID
    /// - Throws: BiometryServiceError
    /// - Returns: activation result
    @discardableResult
    public func requestBiometryAccess(userID: UUID) throws -> Bool {
        return try biometryService.activate()
    }

    public func deleteUser(userID: UUID) throws {
        try _ = user(id: userID)
        userRepository.delete(userID: userID)
    }

    /// Get user by ID
    /// - Parameter id: unique user ID
    /// - Throws: AccessServiceError
    /// - Returns: User object
    public func user(id: UUID) throws -> User {
        guard let user = userRepository.user(userID: id) else {
            throw AccessServiceError.userDoesNotExist
        }
        return user
    }

    /// Get all users.
    /// - Returns: array with User objects
    public func users() -> [User] {
        return userRepository.users()
    }

    /// Update user password
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - password: new plain text password
    /// - Throws: AccessServiceError
    public func updateUserPassword(userID: UUID, password: String) throws {
        var user = try self.user(id: userID)
        user.updatePassword(encryptedPassword: encrypted(password))
        userRepository.save(user: user)
    }

    /// Verifies if the password is correct
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - password: plain text password
    /// - Throws: AccessServiceError
    /// - Returns: true, if password matches user's password, false otherwise
    public func verifyPassword(userID: UUID, password: String) throws -> Bool {
        let user = try self.user(id: userID)
        return user.encryptedPassword == encrypted(password)
    }

    private func encrypted(_ string: String) -> String {
        // A conversion of a Swift string to UTF-8 data cannot fail.
        return SHA256.hash(data: string.data(using: .utf8)!).description
    }

    // MARK: - Authentication

    /// Checks wheter user is authenticated
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - time: time of the check
    /// - Throws: AccessServiceError
    /// - Returns: AuthStatus
    public func authenticationStatus(userID: UUID, at time: Date = Date()) throws -> AuthStatus {
        let user = try self.user(id: userID)
        if let sessionRenewedTime = user.sessionRenewedAt,
            sessionRenewedTime.addingTimeInterval(accessPolicy.sessionDuration) > time {
            return .authenticated
        } else if let accessBlockedTime = user.accessBlockedAt,
            accessBlockedTime.addingTimeInterval(accessPolicy.blockDuration) > time {
            return .blocked(accessBlockedTime.addingTimeInterval(accessPolicy.blockDuration).timeIntervalSince(time))
        } else {
            return .notAuthenticated
        }
    }

    /// Queries the operating system and application capabilities to determine if the
    /// authentication `method` is supported
    /// - Parameter method: AuthMethod
    /// - Throws: BiometryServiceError
    /// - Returns: true if the authentication `method` is supported
    public func isAuthenticationMethodSupported(_ method: AuthMethod) throws -> Bool {
        var supportedSet: AuthMethod = .password
        if method == .password { return true }
        switch try biometryService.biometryType() {
        case .touchID: supportedSet.insert(.touchID)
        case .faceID: supportedSet.insert(.faceID)
        default: break
        }
        return !supportedSet.isDisjoint(with: method)
    }

    /// Queries current state of the app (for example, session state) and the state of biometric service to
    /// determine if the authentication `method` can potentially succeed at this time. Returns false if
    /// access is blocked
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - method: The authentication type
    ///   - time: time of the check
    /// - Throws: AccessServiceError, BiometryServiceError
    /// - Returns: True if the authentication `method` can succeed.
    public func isAuthenticationMethodPossible(
        userID: UUID, method: AuthMethod, at time: Date = Date()) throws -> Bool {
        if case AuthStatus.blocked(_) = try authenticationStatus(userID: userID, at: time) {
            return false
        }
        return try isAuthenticationMethodSupported(method)
    }

    /// Authenticate user
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - password: plain text password
    ///   - time: authentication time
    /// - Throws: AccessServiceError, BiometryServiceError
    /// - Returns: AuthStatus
    public func authenticateUser(userID: UUID, request: AuthRequest, at time: Date = Date()) throws -> AuthStatus {
        if case let AuthStatus.blocked(blockingTimeLeft) = try authenticationStatus(userID: userID, at: time) {
            return .blocked(blockingTimeLeft)
        }
        switch request {
        case .password(let password):
            if try verifyPassword(userID: userID, password: password) {
                return try allowAccess(userID: userID, at: time)
            } else {
                return try denyAccess(userID: userID, at: time)
            }
        case .biometry:
            if try biometryService.authenticate() {
                return try allowAccess(userID: userID, at: time)
            } else {
                return try denyAccess(userID: userID, at: time)
            }
        }
    }

    /// Force deny acess for the user
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - time: authentication time
    /// - Throws: AccessServiceError
    /// - Returns: AuthStatus
    @discardableResult
    public func denyAccess(userID: UUID, at time: Date = Date()) throws -> AuthStatus {
        var user = try self.user(id: userID)
        user.denyAccess()
        if user.failedAuthAttempts > accessPolicy.maxFailedAttempts {
            user.blockAccess(at: time)
        }
        userRepository.save(user: user)
        return try authenticationStatus(userID: userID, at: time)
    }

    /// Force allow acess for the user
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - time: authentication time
    /// - Throws: AccessServiceError
    /// - Returns: AuthStatus
    @discardableResult
    public func allowAccess(userID: UUID, at time: Date = Date()) throws -> AuthStatus {
        var user = try self.user(id: userID)
        user.renewSession(at: time)
        userRepository.save(user: user)
        return .authenticated
    }

    /// Logout user
    /// - Parameter userID: unique user ID
    /// - Throws: AccessServiceError
    public func logout(userID: UUID) throws {
        var user = try self.user(id: userID)
        user.logout()
        userRepository.save(user: user)
    }

    /// Returns number of left authentication attempt before blocking the user
    /// - Parameter userID: unique user ID
    /// - Throws: AccessServiceError
    /// - Returns: authentication attempts left
    public func authenticationAttemptsLeft(userID: UUID) throws -> Int {
        let user = try self.user(id: userID)
        return accessPolicy.maxFailedAttempts > user.failedAuthAttempts ?
            accessPolicy.maxFailedAttempts - user.failedAuthAttempts : 0
    }
}
