//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

/// Implements `Connection` protocol with SQLite3 underneath it. Connection is a one-time openable and closable objects,
/// and cannot be reused. One connection, of course, can generate many prepared
/// statements with `SQLiteConnection.prepare(...)` method.
public class SQLiteConnection: Connection, Assertable {

    private var db: OpaquePointer!
    private let sqlite: CSQLite3
    private var isOpened = false
    private var isClosed = false
    private var statements = [SQLiteStatement]()

    init(sqlite: CSQLite3) {
        self.sqlite = sqlite
    }

    /// Creates a prepared statement from SQL command text input, retains it to keep track of all created
    /// statements until connection is closed. This command may block caller if another thread
    /// is modifying the same database in different connection. The blocking is performed using
    /// `RunLoop.run` method to wake up every 5 milliseconds and check if the database is not busy anymore.
    ///
    /// - Parameter statement: SQL command. Currently only a single SQL command per string is supported.
    /// - Returns: a new `SQLiteStatement` object
    /// - Throws:
    ///     - `Error.connectionIsNotOpened` when connection was not opened yet
    ///     - `Error.connectionIsAlreadyClosed` when connection was closed.
    ///     - `Error.invalidSQLStatement` when there is an error in SQL string
    public func prepare(statement: String) throws -> Statement {
        try assertOpened()
        guard let cstr = statement.cString(using: .utf8) else {
            preconditionFailure("Failed to convert String to C String: \(statement)")
        }
        var outStmt: OpaquePointer?
        var outTail: UnsafePointer<Int8>?
        let status = waitWhileBusy(sqlite.sqlite3_prepare_v2(db, cstr, Int32(cstr.count), &outStmt, &outTail))
        guard status == CSQLite3.SQLITE_OK else {
            if let cString = sqlite.sqlite3_errmsg(db), let message = String(cString: cString, encoding: .utf8) {
                throw SQLiteDatabase.Error.invalidSQLStatement("status: (\(status)) \(message): \(statement)")
            } else {
                throw SQLiteDatabase.Error.invalidSQLStatement("status: (\(status)) unknown error: \(statement)")
            }
        }
        try assertNotNil(outStmt, SQLiteDatabase.Error.invalidSQLStatement("unknown error: \(statement)"))
        let result = SQLiteStatement(sql: statement, db: db, stmt: outStmt!, sqlite: sqlite)
        statements.append(result)
        return result
    }

    private func waitWhileBusy(_ expression: @autoclosure () -> Int32) -> Int32 {
        var status = expression()
        while status == CSQLite3.SQLITE_BUSY {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
            status = expression()
        }
        return status
    }

    public func lastErrorMessage() -> String? {
        guard let cString = sqlite.sqlite3_errmsg(db) else { return nil }
        return String(cString: cString, encoding: .utf8)
    }

    private func assertOpened() throws {
        try assertTrue(isOpened, SQLiteDatabase.Error.connectionIsNotOpened)
        try assertFalse(isClosed, SQLiteDatabase.Error.connectionIsAlreadyClosed)
    }

    private func destroyAllStatements() {
        statements.forEach { $0.finalize() }
    }

    /// Connects to the database at the `url`.
    ///
    /// - Parameter url: the path to SQLite database.
    /// - Throws:
    ///     - `SQLiteDatabase.Error.connectionIsAlreadyClosed` if the connection was closed previously.
    ///     - `SQLiteDatabase.Error.failedToOpenDatabase`, you can get reason using `lastErrorMessage()`
    func open(url: URL) throws {
        try assertFalse(isClosed, SQLiteDatabase.Error.connectionIsAlreadyClosed)
        var conn: OpaquePointer?
        let status = sqlite.sqlite3_open(url.path.cString(using: .utf8), &conn)
        try assertEqual(status, CSQLite3.SQLITE_OK, SQLiteDatabase.Error.failedToOpenDatabase)
        try assertNotNil(conn, SQLiteDatabase.Error.failedToOpenDatabase)
        db = conn
        isOpened = true
    }

    /// Closes the previously opened connection. If another connection is modifying the database, this methods blocks
    /// the caller in the same way as `prepare(...)` method.
    ///
    /// - Throws:
    ///     - `Error.connectionIsNotOpened` when connection was not opened yet
    ///     - `Error.connectionIsAlreadyClosed` when connection was closed.
    ///     - `SQLiteDatabase.Error.databaseBusy` when closing failed.
    func close() throws {
        try assertOpened()
        destroyAllStatements()
        let status = waitWhileBusy(sqlite.sqlite3_close(db))
        try assertEqual(status, CSQLite3.SQLITE_OK, SQLiteDatabase.Error.databaseBusy)
        isClosed = true
    }

}
