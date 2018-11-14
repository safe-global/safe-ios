//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

/// Implements `Statement` protocol with SQLite specifics. `SQLiteStatement`'s setter method indexes for binding
/// SQL values are 1-based.
public class SQLiteStatement: Statement, Assertable {

    private let sql: String
    private let db: OpaquePointer
    private let stmt: OpaquePointer
    private let sqlite: CSQLite3
    private var isFinalized: Bool = false
    private var isExecuted: Bool = false

    /// Creates new `SQLiteStatement` with SQL string and prepared statement from `SQLiteConnection.prepare(...)` call.
    ///
    /// - Parameters:
    ///   - sql: SQL used to create the prepared statement
    ///   - db: sqlite3 pointer to the database connection
    ///   - stmt: sqlite3 pointer to prepared statement
    ///   - sqlite: wrapper around C SQLite3 APIs
    init(sql: String, db: OpaquePointer, stmt: OpaquePointer, sqlite: CSQLite3) {
        self.sql = sql
        self.db = db
        self.stmt = stmt
        self.sqlite = sqlite
    }

    /// Executes (steps) prepared statement and returns `SQLiteResultSet` in case query returns result.
    /// Statements can be executed only once.
    ///
    /// - Returns: new `SQLiteResultSet` if SQL query produces any result rows.
    /// - Throws:
    ///     - `SQLiteDatabase.Error.attemptToExecuteFinalizedStatement` if this statement was finalized (destroyed)
    ///     - `SQLiteDatabase.Error.statementWasAlreadyExecuted` if this statement was executed before.
    ///     - `SQLiteDatabase.Error.runtimeError` with short error description if there was error
    ///         in the database while executing prepared statement.
    ///     - `SQLiteDatabase.Error.invalidStatementState` if underlying SQLite's prepared statement is in wrong state.
    ///         This means a bug in this method implementation. Please contact the developer.
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
                Timer.wait(0.05)
                return try execute()
            } else {
                throw SQLiteDatabase.Error.transactionMustBeRolledBack
            }
        case CSQLite3.SQLITE_ERROR:
            throw SQLiteDatabase.Error.runtimeError(lastErrorMessage())
        case CSQLite3.SQLITE_MISUSE:
            throw SQLiteDatabase.Error.invalidStatementState
        default:
            let message = SQLiteDatabase.errorMessage(from: status, sqlite, db)
            preconditionFailure("Unexpected sqlite3_step() status: \(status), message: \(message)")
        }
    }

    /// Returns short human-readable description of last occurred database error.
    ///
    /// - Returns: Error description
    func lastErrorMessage() -> String {
        guard let cString = sqlite.sqlite3_errmsg(db) else { return "" }
        return String(cString: cString, encoding: .utf8) ?? ""
    }

    /// Destroys underlying objects of a prepared statement. Once finalized, statement is useless.
    func finalize() {
        _ = sqlite.sqlite3_finalize(stmt)
        isFinalized = true
    }

    /// Binds String value to SQL variable at position `index`, variable positions starts from 1.
    /// String must be UTF-8 encodable. The statement must not be executed yet, nor it can be finalized before binding.
    ///
    /// - Parameters:
    ///   - value: value to bind to a position-referenced variable.
    ///   - index: 1-based index
    /// - Throws:
    ///     - `SQLiteDatabase.Error.attemptToBindExecutedStatement` if statement is already executed.
    ///     - `SQLiteDatabase.Error.attemptToBindFinalizedStatement` if statement is already finalized.
    ///     - `SQLiteDatabase.Error.invalidStringBindingValue` if `value` is not encodable as UTF-8 C String.
    ///     - `SQLiteDatabase.Error.statementParameterIndexOutOfRange` if `index` is out of range condition
    ///         was detected by the database after a binding attempt.
    ///     - `SQLiteDatabase.Error.failedToSetStatementParameter` in case of other database errors. You can get short
    ///         error description with `lastErrorMessage()` method.
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

    /// Binds Data value to SQL variable at position `index`, variable positions starts from 1.
    /// The statement must not be executed yet, nor it can be finalized before binding.
    ///
    /// - Parameters:
    ///   - value: value to bind to a position-referenced variable.
    ///   - index: 1-based index
    /// - Throws:
    ///     - `SQLiteDatabase.Error.attemptToBindExecutedStatement` if statement is already executed.
    ///     - `SQLiteDatabase.Error.attemptToBindFinalizedStatement` if statement is already finalized.
    ///     - `SQLiteDatabase.Error.invalidStringBindingValue` if `value` is not encodable as UTF-8 C String.
    ///     - `SQLiteDatabase.Error.statementParameterIndexOutOfRange` if `index` is out of range condition
    ///         was detected by the database after a binding attempt.
    ///     - `SQLiteDatabase.Error.failedToSetStatementParameter` in case of other database errors. You can get short
    ///         error description with `lastErrorMessage()` method.
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

    /// Binds Int value to SQL variable at position `index`, variable positions starts from 1.
    /// The statement must not be executed yet, nor it can be finalized before binding.
    ///
    /// - Parameters:
    ///   - value: value to bind to a position-referenced variable.
    ///   - index: 1-based index
    /// - Throws:
    ///     - `SQLiteDatabase.Error.attemptToBindExecutedStatement` if statement is already executed.
    ///     - `SQLiteDatabase.Error.attemptToBindFinalizedStatement` if statement is already finalized.
    ///     - `SQLiteDatabase.Error.invalidStringBindingValue` if `value` is not encodable as UTF-8 C String.
    ///     - `SQLiteDatabase.Error.statementParameterIndexOutOfRange` if `index` is out of range condition
    ///         was detected by the database after a binding attempt.
    ///     - `SQLiteDatabase.Error.failedToSetStatementParameter` in case of other database errors. You can get short
    ///         error description with `lastErrorMessage()` method.
    public func set(_ value: Int, at index: Int) throws {
        try assertCanBind()
        let status = sqlite.sqlite3_bind_int64(stmt, Int32(index), Int64(value))
        try assertBindSuccess(status)
    }

    /// Binds Double value to SQL variable at position `index`, variable positions starts from 1.
    /// The statement must not be executed yet, nor it can be finalized before binding.
    ///
    /// - Parameters:
    ///   - value: value to bind to a position-referenced variable.
    ///   - index: 1-based index
    /// - Throws:
    ///     - `SQLiteDatabase.Error.attemptToBindExecutedStatement` if statement is already executed.
    ///     - `SQLiteDatabase.Error.attemptToBindFinalizedStatement` if statement is already finalized.
    ///     - `SQLiteDatabase.Error.invalidStringBindingValue` if `value` is not encodable as UTF-8 C String.
    ///     - `SQLiteDatabase.Error.statementParameterIndexOutOfRange` if `index` is out of range condition
    ///         was detected by the database after a binding attempt.
    ///     - `SQLiteDatabase.Error.failedToSetStatementParameter` in case of other database errors. You can get short
    ///         error description with `lastErrorMessage()` method.
    public func set(_ value: Double, at index: Int) throws {
        try assertCanBind()
        let status = sqlite.sqlite3_bind_double(stmt, Int32(index), value)
        try assertBindSuccess(status)
    }

    /// Binds nil (NULL) value to SQL variable at position `index`, variable positions starts from 1.
    /// The statement must not be executed yet, nor it can be finalized before binding.
    ///
    /// - Parameters:
    ///   - value: value to bind to a position-referenced variable.
    ///   - index: 1-based index
    /// - Throws:
    ///     - `SQLiteDatabase.Error.attemptToBindExecutedStatement` if statement is already executed.
    ///     - `SQLiteDatabase.Error.attemptToBindFinalizedStatement` if statement is already finalized.
    ///     - `SQLiteDatabase.Error.invalidStringBindingValue` if `value` is not encodable as UTF-8 C String.
    ///     - `SQLiteDatabase.Error.statementParameterIndexOutOfRange` if `index` is out of range condition
    ///         was detected by the database after a binding attempt.
    ///     - `SQLiteDatabase.Error.failedToSetStatementParameter` in case of other database errors. You can get short
    ///         error description with `lastErrorMessage()` method.
    public func setNil(at index: Int) throws {
        try assertCanBind()
        let status = sqlite.sqlite3_bind_null(stmt, Int32(index))
        try assertBindSuccess(status)
    }

    /// Binds String value to SQL variable referenced by name `key`. Works with `set(value:at:)` under the hood, see
    /// that method for details.
    ///
    /// - Parameters:
    ///   - value: value to bind
    ///   - key: name of the variable
    /// - Throws:
    ///     - `SQLiteDatabase.Error.invalidStatementKeyValue` if named variable was not found in the SQL string.
    ///     - can throw the same errors as `set(value:at:)` method.
    public func set(_ value: String, forKey key: String) throws {
        let index = try parameterIndex(for: key)
        try set(value, at: index)
    }

    /// Binds Data value to SQL variable referenced by name `key`. Works with `set(value:at:)` under the hood, see
    /// that method for details.
    ///
    /// - Parameters:
    ///   - value: value to bind
    ///   - key: name of the variable
    /// - Throws:
    ///     - `SQLiteDatabase.Error.invalidStatementKeyValue` if named variable was not found in the SQL string.
    ///     - can throw the same errors as `set(value:at:)` method.
    public func set(_ value: Data, forKey key: String) throws {
        let index = try parameterIndex(for: key)
        try set(value, at: index)
    }

    /// Binds Int value to SQL variable referenced by name `key`. Works with `set(value:at:)` under the hood, see
    /// that method for details.
    ///
    /// - Parameters:
    ///   - value: value to bind
    ///   - key: name of the variable
    /// - Throws:
    ///     - `SQLiteDatabase.Error.invalidStatementKeyValue` if named variable was not found in the SQL string.
    ///     - can throw the same errors as `set(value:at:)` method.
    public func set(_ value: Int, forKey key: String) throws {
        let index = try parameterIndex(for: key)
        try set(value, at: index)
    }

    /// Binds Double value to SQL variable referenced by name `key`. Works with `set(value:at:)` under the hood, see
    /// that method for details.
    ///
    /// - Parameters:
    ///   - value: value to bind
    ///   - key: name of the variable
    /// - Throws:
    ///     - `SQLiteDatabase.Error.invalidStatementKeyValue` if named variable was not found in the SQL string.
    ///     - can throw the same errors as `set(value:at:)` method.
    public func set(_ value: Double, forKey key: String) throws {
        let index = try parameterIndex(for: key)
        try set(value, at: index)
    }

    /// Binds nil (NULL) value to SQL variable referenced by name `key`. Works with `set(value:at:)` under the hood, see
    /// that method for details.
    ///
    /// - Parameters:
    ///   - value: value to bind
    ///   - key: name of the variable
    /// - Throws:
    ///     - `SQLiteDatabase.Error.invalidStatementKeyValue` if named variable was not found in the SQL string.
    ///     - can throw the same errors as `set(value:at:)` method.
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
        guard status == CSQLite3.SQLITE_OK else {
            let message = SQLiteDatabase.errorMessage(from: status, sqlite, db)
            throw SQLiteDatabase.Error.failedToSetStatementParameter(message)
        }
    }

    private func parameterIndex(for key: String) throws -> Int {
        guard let cString = key.cString(using: .utf8) else { throw SQLiteDatabase.Error.invalidStatementKeyValue }
        let index = sqlite.sqlite3_bind_parameter_index(stmt, cString)
        return Int(index)
    }

}
