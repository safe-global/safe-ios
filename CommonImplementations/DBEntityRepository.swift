//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Database
import Common

open class DBEntityRepository<T: IdentifiableEntity<U>, U: BaseID>: DBAbstractRepository<T> {

    open func find(id: U) -> T? {
        return try! first(of: db.execute(sql: table.findByPrimaryKeySQL,
                                         bindings: primaryKeyBindings(id),
                                         resultMap: objectFromResultSet))
    }

    open func nextID() -> U {
        return U()
    }

    // MARK: Optional to override

    override open func primaryKeyBindings(_ object: T) -> [SQLBindable?] {
        return primaryKeyBindings(object.id)
    }

    open func primaryKeyBindings(_ id: U) -> [SQLBindable?] {
        return [id.id]
    }

}
