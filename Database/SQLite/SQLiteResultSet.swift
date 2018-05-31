//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public class SQLiteResultSet: ResultSet {

    public var isColumnsEmpty: Bool { return columnCount == 0 }
    public var columnCount: Int { return Int(sqlite.sqlite3_column_count(stmt)) }
    private let stmt: OpaquePointer
    private let sqlite: CSQLite3
    private let db: OpaquePointer

    init(db: OpaquePointer, stmt: OpaquePointer, sqlite: CSQLite3) {
        self.db = db
        self.stmt = stmt
        self.sqlite = sqlite
        var status = sqlite.sqlite3_reset(stmt)
        while status == CSQLite3.SQLITE_BUSY {
            status = sqlite.sqlite3_reset(stmt)
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        precondition(status == CSQLite3.SQLITE_OK)
    }

    public func string(at index: Int) -> String? {
        assertIndex(index)
        guard sqlite.sqlite3_column_type(stmt, Int32(index)) != CSQLite3.SQLITE_NULL else { return nil }
        guard let cString = sqlite.sqlite3_column_text(stmt, Int32(index)) else {
            return nil
        }
        let bytesCount = sqlite.sqlite3_column_bytes(stmt, Int32(index))
        return cString.withMemoryRebound(to: CChar.self, capacity: Int(bytesCount)) { ptr -> String? in
            String(cString: ptr, encoding: .utf8)
        }
    }

    public func data(at index: Int) -> Data? {
        assertIndex(index)
        guard sqlite.sqlite3_column_type(stmt, Int32(index)) != CSQLite3.SQLITE_NULL else { return nil }
        guard let ptr = sqlite.sqlite3_column_blob(stmt, Int32(index)) else { return nil }
        let bytesCount = sqlite.sqlite3_column_bytes(stmt, Int32(index))
        return Data(bytes: ptr, count: Int(bytesCount))
    }

    private func assertIndex(_ index: Int) {
        precondition((0..<columnCount).contains(index), "Index out of column count range")
    }

    public func int(at index: Int) -> Int? {
        assertIndex(index)
        guard sqlite.sqlite3_column_type(stmt, Int32(index)) != CSQLite3.SQLITE_NULL else { return nil }
        return Int(sqlite.sqlite3_column_int64(stmt, Int32(index)))
    }

    public func double(at index: Int) -> Double? {
        assertIndex(index)
        guard sqlite.sqlite3_column_type(stmt, Int32(index)) != CSQLite3.SQLITE_NULL else { return nil }
        return sqlite.sqlite3_column_double(stmt, Int32(index))
    }

    public func advanceToNextRow() throws -> Bool {
        let status = sqlite.sqlite3_step(stmt)
        switch status {
        case CSQLite3.SQLITE_DONE:
            return false
        case CSQLite3.SQLITE_ROW:
            return true
        case CSQLite3.SQLITE_BUSY:
            let isOutsideOfExplicitTransaction = sqlite.sqlite3_get_autocommit(db) != 0
            if isOutsideOfExplicitTransaction {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
                return try advanceToNextRow()
            } else {
                throw SQLiteDatabase.Error.transactionMustBeRolledBack
            }
        default:
            preconditionFailure("Unexpected sqlite3_step() status: \(status)")
        }
    }
}
