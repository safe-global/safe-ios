//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import IdentityAccessDomainModel
import CommonTestSupport

public class InMemorySecureStore: SecureStore {

    var storedPassword: String?
    var storedMnemonic: Mnemonic?
    var storedPrivateKey: PrivateKey?

    public var shouldThrow: Bool = false

    public init() {}

    private func throwIfNeeded() throws {
        if shouldThrow { throw TestError.error }
    }

    public func password() throws -> String? {
        try throwIfNeeded()
        return storedPassword
    }

    public func savePassword(_ password: String) throws {
        try throwIfNeeded()
        storedPassword = password
    }

    public func removePassword() throws {
        try throwIfNeeded()
        storedPassword = nil
    }

    public func privateKey() throws -> PrivateKey? {
        try throwIfNeeded()
        return storedPrivateKey
    }

    public func savePrivateKey(_ privateKey: PrivateKey) throws {
        try throwIfNeeded()
        storedPrivateKey = privateKey
    }

    public func removePrivateKey() throws {
        try throwIfNeeded()
        storedPrivateKey = nil
    }

    public func mnemonic() throws -> Mnemonic? {
        try throwIfNeeded()
        return storedMnemonic
    }

    public func saveMnemonic(_ mnemonic: Mnemonic) throws {
        try throwIfNeeded()
        storedMnemonic = mnemonic
    }

    public func removeMnemonic() throws {
        try throwIfNeeded()
        storedMnemonic = nil
    }

}
