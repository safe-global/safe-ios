//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Database
import Common

open class DBEntityRepository<T: IdentifiableEntity<U>, U: BaseID> {

    public let db: Database

    public init(db: Database) {
        self.db = db
    }

    open func setUp() {
        try! db.execute(sql: table.createTableSQL)
    }

    open func save(_ object: T) {
        try! db.execute(sql: table.insertSQL, bindings: insertionBindings(object))
    }

    open func remove(_ object: T) {
        try! db.execute(sql: table.deleteSQL, bindings: primaryKeyBindings(object))
    }

    open func findFirst() -> T? {
        return try! first(of: db.execute(sql: table.findFirstSQL, resultMap: objectFromResultSet))
    }

    open func find(id: U) -> T? {
        return try! first(of: db.execute(sql: table.findByPrimaryKeySQL,
                                         bindings: primaryKeyBindings(id),
                                         resultMap: objectFromResultSet))
    }

    open func find(key: String, keyValue: String, orderBy: String) -> [T] {
        return try! unwrapped(db.execute(sql: table.findSQL(key: key, orderBy: orderBy),
                                         bindings: [keyValue],
                                         resultMap: objectFromResultSet))
    }

    open func all() -> [T] {
        return try! unwrapped(db.execute(sql: table.findAllSQL, resultMap: objectFromResultSet))
    }

    open func first(of values: [T?]) -> T? {
        return unwrapped(values).first
    }

    open func unwrapped(_ values: [T?]) -> [T] {
        return values.compactMap { $0 }
    }

    open func nextID() -> U {
        return U()
    }

    open func bindable(_ values: [DBSerializable?]) -> [SQLBindable?] {
        return values.map { $0?.serializedValue }
    }

    // MARK: - Override these methods

    open var table: TableSchema { preconditionFailure("Not implemented") }

    open func insertionBindings(_ object: T) -> [SQLBindable?] {
        preconditionFailure("Not implemented")
    }

    open func objectFromResultSet(_ rs: ResultSet) throws -> T? {
        preconditionFailure("Not implemented")
    }

    // MARK: Optional to override

    open func primaryKeyBindings(_ object: T) -> [SQLBindable?] {
        return primaryKeyBindings(object.id)
    }

    open func primaryKeyBindings(_ id: U) -> [SQLBindable?] {
        return [id.id]
    }

}
