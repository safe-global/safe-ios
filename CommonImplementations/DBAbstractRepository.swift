//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import Database
import Common

open class DBAbstractRepository<T> {

    // MARK: - Methods to override

    open var table: TableSchema {
        preconditionFailure()
    }

    open func insertionBindings(_ object: T) -> [SQLBindable?] {
        preconditionFailure("Not implemented")
    }

    open func objectFromResultSet(_ rs: ResultSet) throws -> T? {
        preconditionFailure("Not implemented")
    }

    open func primaryKeyBindings(_ item: T) -> [SQLBindable?] {
        preconditionFailure()
    }

    // MARK: - Public Interface

    public let db: Database

    public init(db: Database) {
        self.db = db
    }

    open func setUp() {
        try! db.execute(sql: table.createTableSQL)
    }

    open func save(_ item: T) {
        try! db.execute(sql: table.insertSQL, bindings: insertionBindings(item))
    }

    open func remove(_ item: T) {
        try! db.execute(sql: table.deleteSQL, bindings: primaryKeyBindings(item))
    }

    open func findFirst() -> T? {
        return try! first(of: db.execute(sql: table.findFirstSQL, resultMap: objectFromResultSet))
    }

    open func find(key: String, value: SQLBindable, caseSensitive: Bool = true, orderBy: String) -> [T] {
        return try! unwrapped(db.execute(sql: table.findSQL(key: key, caseSensitive: caseSensitive, orderBy: orderBy),
                                         bindings: [value],
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

    open func bindable(_ values: [DBSerializable?]) -> [SQLBindable?] {
        return values.map { $0?.serializedValue }
    }

}
