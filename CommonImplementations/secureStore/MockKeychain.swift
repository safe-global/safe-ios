//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import IdentityAccessDomainModel
import CommonTestSupport

public class MockKeychain: SecureStore {

    private var storedPassword: String?
    public var throwsOnSavePassword = false
    public var throwsOnGetPassword = false
    public var throwsOnRemovePassword = false

    public init() {}

    public func password() throws -> String? {
        if throwsOnGetPassword {
            throw TestError.error
        }
        return storedPassword
    }

    public func savePassword(_ password: String) throws {
        if throwsOnSavePassword {
            throw TestError.error
        }
        storedPassword = password
    }

    public func removePassword() throws {
        if throwsOnRemovePassword {
            throw TestError.error
        }
        storedPassword = nil
    }

    public func privateKey() throws -> PrivateKey? { return nil }

    public func savePrivateKey(_ privateKey: PrivateKey) throws {}

    public func removePrivateKey() throws {}

    public func mnemonic() throws -> Mnemonic? { return nil }

    public func saveMnemonic(_ mnemonic: Mnemonic) throws {}

    public func removeMnemonic() throws {}

}
