//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Biometric authentication types
///
/// - none: no biometric authentication
/// - touchID: touch ID
/// - faceID: face ID
public enum BiometryType {
    case none, touchID, faceID
}

/// Provides user facing text description of reasons to activate biometry and to authenticate with biometry.
public struct BiometryReason {
    var touchIDActivation: String
    var touchIDAuth: String
    var faceIDActivation: String
    var faceIDAuth: String
    var unrecognizedBiometryType: String

    public init(touchIDActivation: String,
                touchIDAuth: String,
                faceIDActivation: String,
                faceIDAuth: String,
                unrecognizedBiometryType: String) {
        self.touchIDActivation = touchIDActivation
        self.touchIDAuth = touchIDAuth
        self.faceIDActivation = faceIDActivation
        self.faceIDAuth = faceIDAuth
        self.unrecognizedBiometryType = unrecognizedBiometryType
    }
}

/// Represents biometric authentication service provided by the operating system
public protocol BiometryService {
    /// Structure with user facing messags related to biometry activatation and usage
    var biometryReason: BiometryReason { get }

    /// Available biometry type
    /// - Throws: error if underlying service errored
    /// - Returns: available biometry type on the device
    func biometryType() throws -> BiometryType

    /// Activates biometric authentication. This requests user to allow biometric authentication
    /// - Throws: error if underlying service errored
    /// - Returns: True if user successfully activated biometry
    func activate() throws -> Bool

    /// Authenticates user with activated biometry type
    /// - Throws: Throws error when authentication was cancelled by user, system, or underlying auth mechanism failed
    /// - Returns: True if user authenticated successfully, false when authentication credentials were wrong
    func authenticate() throws -> Bool
}
