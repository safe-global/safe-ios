//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common
import CommonTestSupport

public class InMemorySecureStore: SecureStore {

    public var shouldThrow: Bool = false
    private var values = [String: Data]()

    public init() {}


    public func save(data: Data, forKey: String) throws {
        values[forKey] = data
    }

    public func data(forKey: String) throws -> Data? {
        return values[forKey]
    }

    public func removeData(forKey: String) throws {
        values.removeValue(forKey: forKey)
    }

}
