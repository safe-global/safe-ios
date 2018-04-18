//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

open class IdentifiableEntity<T: Hashable>: Hashable, Assertable {

    public let id: T
    public var hashValue: Int { return id.hashValue }

    public static func ==(lhs: IdentifiableEntity<T>, rhs: IdentifiableEntity<T>) -> Bool {
        return lhs.id == rhs.id
    }

    public init(id: T) {
        self.id = id
    }

}
