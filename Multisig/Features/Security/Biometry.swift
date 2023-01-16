//
//  Biometry.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.01.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import LocalAuthentication

class Biometry {

    let context: LAContext

    init(context: LAContext = LAContext()) {
        self.context = context
    }

    /// Is device hardware supports the biometry
    func isSupported() throws -> Bool {
        #if DEBUG
        if let testResult = _forced_isSupported {
            return testResult
        }
        #endif


        switch try type() {
        case .touchID, .faceID:
            return true
        case .none:
            return false
        @unknown default:
            return false
        }
    }

    #if DEBUG
    /// Override `isSupported` value for testing
    var _forced_isSupported: Bool?
    #endif


    func type() throws -> LABiometryType {
        _ = try canEvaluate(policy: .deviceOwnerAuthentication)
        return context.biometryType
    }

    func canEvaluate(policy: LAPolicy) throws -> Bool {
        var error: NSError!
        let success = context.canEvaluatePolicy(policy, error: &error)
        guard success else {
            throw error
        }
        return success
    }

    var showsFallbackButton: Bool {
        get {
            context.localizedFallbackTitle == nil
        }
        set {
            context.localizedFallbackTitle = newValue ? nil : ""
        }
    }

    func evaluate(policy: LAPolicy, reason: String, completion: @escaping (_ result: Result<Void, Error>) -> Void) {
        context.evaluatePolicy(policy, localizedReason: reason) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    completion(.success( () ))
                } else {
                    completion(.failure( error! ))
                }
            }
        }
    }

}
