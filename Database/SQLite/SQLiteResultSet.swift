//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

/// Implements a `ResultSet` protocol with SQLite3 specifics. ResultSet's column indexes are 0-based.
public class SQLiteResultSet: ResultSet {

    /// True if no columns in the result set
    public var isColumnsEmpty: Bool { return columnCount == 0 }
    /// Returns number of columns in the result set
    public var columnCount: Int { return Int(sqlite.sqlite3_column_count(stmt)) }
    private let stmt: OpaquePointer
    private let sqlite: CSQLite3
    private let db: OpaquePointer

    /// Creates new result set, resetting the `stmt` to return to the pre-first result row.
    ///
    /// - Parameters:
    ///   - db: sqlite3 database pointer
    ///   - stmt: sqlite3 statement pointer
    ///   - sqlite: wrapper around CSQLite3 API
    init(db: OpaquePointer, stmt: OpaquePointer, sqlite: CSQLite3) {
        self.db = db
        self.stmt = stmt
        self.sqlite = sqlite
        var status = sqlite.sqlite3_reset(stmt)
        while status == CSQLite3.SQLITE_BUSY {
            Timer.wait(0.05)
            status = sqlite.sqlite3_reset(stmt)
        }
        precondition(status == CSQLite3.SQLITE_OK, SQLiteDatabase.errorMessage(from: status, sqlite, db))
    }

    /// Returns string at specified column index (0-based). Index must be within `columnCount`.
    ///
    /// - Parameter index: index of a column in the result set
    /// - Returns: String or nil
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

    /// Returns Data at specified column index (0-based). Index must be within `columnCount`.
    ///
    /// - Parameter index: index of a column in the result set
    /// - Returns: Data or nil
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

    /// Returns Data at specified column index (0-based). Index must be within `columnCount`.
    ///
    /// - Parameter index: index of a column in the result set
    /// - Returns: Data or nil
    public func int(at index: Int) -> Int? {
        assertIndex(index)
        guard sqlite.sqlite3_column_type(stmt, Int32(index)) != CSQLite3.SQLITE_NULL else { return nil }
        return Int(sqlite.sqlite3_column_int64(stmt, Int32(index)))
    }

    /// Returns Data at specified column index (0-based). Index must be within `columnCount`.
    ///
    /// - Parameter index: index of a column in the result set
    /// - Returns: Data or nil
    public func double(at index: Int) -> Double? {
        assertIndex(index)
        guard sqlite.sqlite3_column_type(stmt, Int32(index)) != CSQLite3.SQLITE_NULL else { return nil }
        return sqlite.sqlite3_column_double(stmt, Int32(index))
    }

    /// Moves result set to the next row and returns true if no more rows available.
    ///
    /// - Returns: True if no more rows available and this method should not be called anymore.
    /// - Throws:
    ///     - `SQLiteDatabase.Error.transactionMustBeRolledBack` if ongoing transaction must be rolled back.
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
                Timer.wait(0.01)
                return try advanceToNextRow()
            } else {
                throw SQLiteDatabase.Error.transactionMustBeRolledBack
            }
        default:
            let message = SQLiteDatabase.errorMessage(from: status, sqlite, db)
            preconditionFailure("Unexpected sqlite3_step() status: \(status), message: \(message)")
        }
    }
}
