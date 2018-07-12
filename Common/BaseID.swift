//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Base generic class for all UUID-based identifier classes, used to identify Entities.
///
/// To implement your identifier class, just inherit from the `BaseID`:
///
///     class MyID: BaseID {}
///
///     // instantiation
///     let id = MyID()
///
open class BaseID: Hashable, Assertable, CustomStringConvertible {

    /// Errors thrown if ID is invalid
    ///
    public enum Error: Swift.Error, Hashable {
        /// the ID provided to `BaseID.init(...)` method is invalid.
        case invalidID
    }

    public let id: String
    public var hashValue: Int { return id.hashValue &* 31 } // hashValue * 31 may overflow, so using &* operator
    public var description: String { return id }

    open static func ==(lhs: BaseID, rhs: BaseID) -> Bool {
        return lhs.id == rhs.id
    }

    /// Creates new identifier from string. By default takes random UUID string.
    ///
    /// - Parameter id: String to initialize the identifier with
    /// - Throws: Throws `Error.invalidID` if the `id` parameter is not 36 characters long.
    public required init(_ id: String = UUID().uuidString) {
        self.id = id
    }

}
