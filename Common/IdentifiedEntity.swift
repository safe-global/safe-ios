//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

open class IdentifiedEntity<T: Hashable>: Hashable, Assertable {

    public let id: T
    public var hashValue: Int { return id.hashValue }

    public static func ==(lhs: IdentifiedEntity<T>, rhs: IdentifiedEntity<T>) -> Bool {
        return lhs.id == rhs.id
    }

    public init(id: T) {
        self.id = id
    }

}
