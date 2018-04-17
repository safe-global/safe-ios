//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

open class IdentifiedEntity<T: Hashable>: Hashable, Assertable {

    public let ID: T
    public var hashValue: Int { return ID.hashValue }

    public static func ==(lhs: IdentifiedEntity<T>, rhs: IdentifiedEntity<T>) -> Bool {
        return lhs.ID == rhs.ID
    }

    public init(id: T) {
        self.ID = id
    }

}
