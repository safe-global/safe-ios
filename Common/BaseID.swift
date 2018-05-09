//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

open class BaseID: Hashable, Assertable {

    public enum Error: Swift.Error, Hashable {
        case invalidID
    }

    public let id: String
    public var hashValue: Int { return id.hashValue &* 31 } // hashValue * 31 may overflow, so using &* operator

    open static func ==(lhs: BaseID, rhs: BaseID) -> Bool {
        return lhs.id == rhs.id
    }

    public required init(_ id: String = UUID().uuidString) throws {
        self.id = id
        try assertTrue(id.count == 36, Error.invalidID)
    }
}
