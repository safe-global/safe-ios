//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public class SQLiteStatement: Statement, Assertable {

    private let sql: String
    private let db: OpaquePointer
    private let stmt: OpaquePointer
    private let sqlite: CSQLite3
    private var isFinalized: Bool = false
    private var isExecuted: Bool = false

    init(sql: String, db: OpaquePointer, stmt: OpaquePointer, sqlite: CSQLite3) {
        self.sql = sql
        self.db = db
        self.stmt = stmt
        self.sqlite = sqlite
    }

    @discardableResult
    public func execute() throws -> ResultSet? {
        try assertFalse(isFinalized, SQLiteDatabase.Error.attemptToExecuteFinalizedStatement)
        try assertFalse(isExecuted, SQLiteDatabase.Error.statementWasAlreadyExecuted)
        let status = sqlite.sqlite3_step(stmt)
        switch status {
        case CSQLite3.SQLITE_DONE:
            isExecuted = true
            return nil
        case CSQLite3.SQLITE_ROW:
            isExecuted = true
            return SQLiteResultSet(db: db, stmt: stmt, sqlite: sqlite)
        case CSQLite3.SQLITE_BUSY:
            let isInsideExplicitTransaction = sqlite.sqlite3_get_autocommit(db) == 0
            let isCommitStatement = sql.localizedCaseInsensitiveContains("commit")
            if isCommitStatement || !isInsideExplicitTransaction {
                // recurse until not busy with delay
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
                return try execute()
            } else {
                throw SQLiteDatabase.Error.transactionMustBeRolledBack
            }
        case CSQLite3.SQLITE_ERROR:
            throw SQLiteDatabase.Error.runtimeError
        case CSQLite3.SQLITE_MISUSE:
            throw SQLiteDatabase.Error.invalidStatementState
        default:
            preconditionFailure("Unexpected sqlite3_step() status: \(status)")
        }
    }

    func finalize() {
        _ = sqlite.sqlite3_finalize(stmt)
        isFinalized = true
    }

    public func set(_ value: String, at index: Int) throws {
        try assertCanBind()
        guard let cString = value.cString(using: .utf8) else { throw SQLiteDatabase.Error.invalidStringBindingValue }
        let status = sqlite.sqlite3_bind_text(stmt,
                                              Int32(index),
                                              cString,
                                              Int32(cString.count),
                                              CSQLite3.SQLITE_TRANSIENT)
        try assertBindSuccess(status)
    }

    public func set(_ value: Data, at index: Int) throws {
        try assertCanBind()
        let byteCount = value.count
        let status = value.withUnsafeBytes { ptr -> Int32 in
            sqlite.sqlite3_bind_blob(stmt,
                                     Int32(index),
                                     UnsafeRawPointer(ptr),
                                     Int32(byteCount),
                                     CSQLite3.SQLITE_TRANSIENT)
        }
        try assertBindSuccess(status)
    }

    public func set(_ value: Int, at index: Int) throws {
        try assertCanBind()
        let status = sqlite.sqlite3_bind_int64(stmt, Int32(index), Int64(value))
        try assertBindSuccess(status)
    }



    public func set(_ value: Double, at index: Int) throws {
        try assertCanBind()
        let status = sqlite.sqlite3_bind_double(stmt, Int32(index), value)
        try assertBindSuccess(status)
    }

    public func setNil(at index: Int) throws {
        try assertCanBind()
        let status = sqlite.sqlite3_bind_null(stmt, Int32(index))
        try assertBindSuccess(status)
    }

    public func set(_ value: String, forKey key: String) throws {
        let index = try parameterIndex(for: key)
        try set(value, at: index)
    }

    public func set(_ value: Data, forKey key: String) throws {
        let index = try parameterIndex(for: key)
        try set(value, at: index)
    }

    public func set(_ value: Int, forKey key: String) throws {
        let index = try parameterIndex(for: key)
        try set(value, at: index)
    }

    public func set(_ value: Double, forKey key: String) throws {
        let index = try parameterIndex(for: key)
        try set(value, at: index)
    }

    public func setNil(forKey key: String) throws {
        let index = try parameterIndex(for: key)
        try setNil(at: index)
    }

    private func assertCanBind() throws {
        try assertFalse(isExecuted, SQLiteDatabase.Error.attemptToBindExecutedStatement)
        try assertFalse(isFinalized, SQLiteDatabase.Error.attemptToBindFinalizedStatement)
    }

    private func assertBindSuccess(_ status: Int32) throws {
        try assertNotEqual(status, CSQLite3.SQLITE_RANGE, SQLiteDatabase.Error.statementParameterIndexOutOfRange)
        try assertEqual(status, CSQLite3.SQLITE_OK, SQLiteDatabase.Error.failedToSetStatementParameter)
    }

    private func parameterIndex(for key: String) throws -> Int {
        guard let cString = key.cString(using: .utf8) else { throw SQLiteDatabase.Error.invalidStatementKeyValue }
        let index = sqlite.sqlite3_bind_parameter_index(stmt, cString)
        return Int(index)
    }

}
