//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Database

// swiftlint:disable file_length
class SQLiteDatabaseTests: XCTestCase {

    let fm = MockFileManager()
    let sqlite = MockCSQLite3()
    var db: SQLiteDatabase!
    var stmt: SQLiteStatement!
    var conn: SQLiteConnection!
    var rs: SQLiteResultSet!
    let bundleId = "my_random_bundle_id"

    enum Error: String, LocalizedError, Hashable {
        case databaseAlreadyExists
        case bundleIdentifierNotFound
        case databaseURLNotFound
        case resultSetMissing
        case unexpectedStatement
        case unexpectedConnection

        var errorDescription: String? {
            return rawValue
        }
    }

    override func setUp() {
        super.setUp()
        db = SQLiteDatabase(name: "MyTestDb", fileManager: fm, sqlite: sqlite, bundleId: bundleId)
    }

    override func tearDown() {
        super.tearDown()
        XCTAssertNoThrow(try db.destroy())
    }

    func test_hasName() {
        XCTAssertEqual(db.name, "MyTestDb")
    }

    func test_whenAppSupportNotExists_thenThrows() throws {
        let appDirectory = try fm.appSupportURL()
        fm.notExistingURLs = [appDirectory]
        XCTAssertFalse(fm.fileExists(atPath: appDirectory.path))
        assertThrows(try db.create(), SQLiteDatabase.Error.applicationSupportDirNotFound)
    }

    func test_whenDatabaseExists_thenThrrows() throws {
        let appDirectory = try fm.appSupportURL()
        let databaseURL = appDirectory.appendingPathComponent(bundleId)
            .appendingPathComponent(db.name)
            .appendingPathExtension("db")
        fm.existingURLs = [databaseURL]
        assertThrows(try db.create(), SQLiteDatabase.Error.databaseAlreadyExists)
    }

    func test_createsDatabaseFile() throws {
        try db.create()
        guard let url = db.url else { throw Error.databaseURLNotFound }
        XCTAssertTrue(fm.fileExists(atPath: url.path))
    }

    func test_whenCreated_thenExists() throws {
        try db.create()
        XCTAssertTrue(db.exists)
    }

    func test_whenDestroyed_thenNotExists() throws {
        try db.create()
        try db.destroy()
        XCTAssertFalse(db.exists)
    }

    func test_whenNotCreated_thenNotExists() throws {
        XCTAssertFalse(db.exists)
    }

    func test_whenConnectingToNonExistingDatabase_thenThrows() throws {
        assertThrows(try db.connection(), SQLiteDatabase.Error.databaseDoesNotExist)
    }

    func test_whenConnecting_thenOpensSqlite() throws {
        try givenConnection()
        XCTAssertEqual(sqlite.openedFilename, db.url.path)
    }

    func test_beforeConnecting_whenVersionNotMatches_thenThrows() throws {
        sqlite.version = "1"
        sqlite.libversion_result = "2"
        try db.create()
        assertThrows(try db.connection(), SQLiteDatabase.Error.invalidSQLiteVersion)
    }

    func test_whenMajorVersionIsEqual_thenDoesNotThrow() throws {
        sqlite.version = "3.19.5"
        sqlite.libversion_result = "3.14.0"
        try db.create()
        sqlite.open_pointer_result = opaquePointer()
        XCTAssertNoThrow(try db.connection())
    }

    func test_beforeConnecting_whenSourceIDNotMatches_thenThrows() throws {
        sqlite.sourceID = "1"
        sqlite.sourceid_result = "2"
        try db.create()
        assertThrows(try db.connection(), SQLiteDatabase.Error.invalidSQLiteVersion)
    }

    func test_whenMinorVersionsDifferent_thenSourceIdAndVersionNumberCanBeDifferent() throws {
        sqlite.version = "3.19.5"
        sqlite.libversion_result = "3.14.0"
        sqlite.sourceID = "1"
        sqlite.sourceid_result = "2"
        sqlite.number = 1
        sqlite.libversion_number_result = 2
        try db.create()
        sqlite.open_pointer_result = opaquePointer()
        XCTAssertNoThrow(try db.connection())
    }

    func test_beforeConnecting_whenVersionNumberNotMatches_thenThrows() throws {
        sqlite.number = 1
        sqlite.libversion_number_result = 2
        try db.create()
        assertThrows(try db.connection(), SQLiteDatabase.Error.invalidSQLiteVersion)
    }

    func test_whenConnectionReturnsError_thenThrows() throws {
        sqlite.open_result = CSQLite3.SQLITE_IOERR_LOCK
        try db.create()
        let message = SQLiteDatabase.errorMessage(from: sqlite.open_result, sqlite, sqlite.open_pointer_result)
        assertThrows(try db.connection(),
                     SQLiteDatabase.Error.failedToOpenDatabase("status: (\(sqlite.open_result)) \(message)"))
    }

    func test_whenConnectionReturnsNilPointer_thenThrows() throws {
        sqlite.open_pointer_result = nil
        try db.create()
        assertThrows(try db.connection(), SQLiteDatabase.Error.failedToOpenDatabase("connection is nil"))
    }

    func test_connectionClosesSQLiteDatabase() throws {
        try givenConnection()
        sqlite.close_result = CSQLite3.SQLITE_OK
        try db.close(conn)
        XCTAssertTrue(sqlite.close_pointer == sqlite.open_pointer_result)
    }

    func test_whenClosingNotPossible_throwsError() throws {
        try givenConnection()
        sqlite.close_result = CSQLite3.SQLITE_ERROR
        let message = SQLiteDatabase.errorMessage(from: sqlite.close_result, sqlite, sqlite.close_pointer)
        assertThrows(try db.close(conn), SQLiteDatabase.Error.failedToCloseDatabase(message))
        sqlite.close_result = CSQLite3.SQLITE_OK
    }

    func test_whenClosingNotOpenConnection_throwsError() throws {
        let conn = SQLiteConnection(sqlite: sqlite)
        assertThrows(try conn.close(), SQLiteDatabase.Error.connectionIsNotOpened)
    }

    func test_whenNotOpenedAndPreparingStatement_thenThrows() {
        let conn = SQLiteConnection(sqlite: sqlite)
        assertThrows(try conn.prepare(statement: "some"), SQLiteDatabase.Error.connectionIsNotOpened)
    }

    func test_prepareStatement_passesCorrectArguments() throws {
        try givenConnection()

        sqlite.prepare_result = CSQLite3.SQLITE_OK
        sqlite.prepare_out_ppStmt = opaquePointer()
        sqlite.prepare_out_pzTail = nil
        _ = try conn.prepare(statement: "some")

        XCTAssertEqual(sqlite.prepare_in_db, sqlite.open_pointer_result)
        XCTAssertEqual(sqlite.prepare_in_zSql_string, "some")

        guard let bytes = sqlite.prepare_in_nByte else { XCTFail("Argument missing"); return }
        XCTAssertEqual(Int(bytes), "some".cString(using: .utf8)!.count)
    }

    func test_preapreStatement_whenFailed_thenThrowsError() throws {
        try givenConnection()
        sqlite.prepare_out_ppStmt = opaquePointer()
        sqlite.prepare_out_pzTail = nil
        sqlite.prepare_result = CSQLite3.SQLITE_ERROR
        sqlite.errmsg_result = "error"
        assertThrows(try conn.prepare(statement: "some"),
                     SQLiteDatabase.Error.invalidSQLStatement("status: (1) error: some"))
    }

    func test_prepareStatement_whenReceivesNilStatement_thenThrowsError() throws {
        try givenConnection()
        sqlite.prepare_result = CSQLite3.SQLITE_OK
        sqlite.prepare_out_ppStmt = nil
        sqlite.prepare_out_pzTail = nil
        assertThrows(try conn.prepare(statement: "some"),
                     SQLiteDatabase.Error.invalidSQLStatement("unknown error: some"))
    }

    func test_whenConnectionIsClosed_thenPreparedStatementIsFinalizedAutomatically() throws {
        try givenConnection()

        sqlite.prepare_result = CSQLite3.SQLITE_OK
        sqlite.prepare_out_ppStmt = opaquePointer()
        sqlite.prepare_out_pzTail = nil
        _ = try conn.prepare(statement: "my statement")

        sqlite.finalize_result = CSQLite3.SQLITE_OK
        try db.close(conn)

        XCTAssertEqual(sqlite.finalize_in_pStmt, sqlite.prepare_out_ppStmt)
    }

    func test_whenMultipleStatementsCreated_finalizesAll() throws {
        try givenConnection()

        let stmt1 = opaquePointer()
        sqlite.prepare_result = CSQLite3.SQLITE_OK
        sqlite.prepare_out_ppStmt = stmt1
        sqlite.prepare_out_pzTail = nil
        _ = try conn.prepare(statement: "my statement")

        let stmt2 = opaquePointer()
        sqlite.prepare_result = CSQLite3.SQLITE_OK
        sqlite.prepare_out_ppStmt = stmt2
        sqlite.prepare_out_pzTail = nil
        _ = try conn.prepare(statement: "my othe statement")

        sqlite.finalize_result = CSQLite3.SQLITE_OK
        try db.close(conn)

        XCTAssertEqual(sqlite.finalize_in_pStmt_list, [stmt1, stmt2])
    }

    func test_whenStatementFinalizedAndExecutes_thenThrows() throws {
        let statement = SQLiteStatement(sql: "some", db: opaquePointer(), stmt: opaquePointer(), sqlite: sqlite)
        statement.finalize()
        assertThrows(try statement.execute(), SQLiteDatabase.Error.attemptToExecuteFinalizedStatement)
    }

    func test_whenConnectionWasClosedAndThenOpened_thenThrows() throws {
        try givenClosedConnection()
        assertThrows(try conn.open(url: db.url), SQLiteDatabase.Error.connectionIsAlreadyClosed)
    }

    func test_whenConnectionWasClosedAndThenClosedAgain_thenThrows() throws {
        try givenClosedConnection()
        assertThrows(try db.close(conn), SQLiteDatabase.Error.connectionIsAlreadyClosed)
    }

    func test_whenConnectionClosed_thenPrepareThrows() throws {
        try givenClosedConnection()
        assertThrows(try conn.prepare(statement: "some"), SQLiteDatabase.Error.connectionIsAlreadyClosed)
    }

    func test_whenDatabaseDeinit_thenConnectionsAreClosed() throws {
        try givenConnection()
        try db.destroy()
        assertThrows(try conn.prepare(statement: "some"), SQLiteDatabase.Error.connectionIsAlreadyClosed)
    }

    func test_canCreateAfterDestroy() throws {
        try givenConnection()
        try db.destroy()
        try db.create()
        try db.destroy()
    }

    func test_execute_whenStepReturnsDone_thenOk() throws {
        try givenPreparedStatement()
        try stmt.execute()
        XCTAssertNotNil(sqlite.step_in_pStmt)
    }

    func test_whenExecutedAndExecutesAgain_thenThrows() throws {
        try givenPreparedStatement()
        try stmt.execute()
        assertThrows(try stmt.execute(), SQLiteDatabase.Error.statementWasAlreadyExecuted)
    }

    func test_whenExecuteError_thenThrows() throws {
        try givenPreparedStatement()
        sqlite.step_results = [CSQLite3.SQLITE_ERROR]
        assertThrows(try stmt.execute(), SQLiteDatabase.Error.runtimeError(""))
    }

    func test_whenExecuteMisuse_thenTrows() throws {
        try givenPreparedStatement()
        sqlite.step_results = [CSQLite3.SQLITE_MISUSE]
        assertThrows(try stmt.execute(), SQLiteDatabase.Error.invalidStatementState)
    }

    func test_whenStatementIsNotCommitAndOccursInsideExplicitTransaction_thenThrows() throws {
        try givenPreparedStatement()
        sqlite.step_results = [CSQLite3.SQLITE_BUSY]
        // 0 means False - autocommit is disabled - inside BEGIN...COMMIT
        sqlite.get_autocommit_result = 0
        assertThrows(try stmt.execute(), SQLiteDatabase.Error.transactionMustBeRolledBack)
    }

    func test_whenStatementIsCommitAndBusy_thenRetries() throws {
        try givenPreparedStatement("COMMENT;")
        sqlite.step_results = [CSQLite3.SQLITE_BUSY, CSQLite3.SQLITE_BUSY, CSQLite3.SQLITE_DONE]
        try stmt.execute()
        XCTAssertEqual(sqlite.step_result_index, sqlite.step_results.count)
    }

    func test_whenStatementNotCommitAndBusyAndOutsideExplicitTransaction_thenRetries() throws {
        try givenPreparedStatement()
        sqlite.step_results = [CSQLite3.SQLITE_BUSY, CSQLite3.SQLITE_BUSY, CSQLite3.SQLITE_DONE]
        // autocommit enabled - means not in BEGIN...COMMIT
        sqlite.get_autocommit_result = 1
        try stmt.execute()
        XCTAssertEqual(sqlite.step_result_index, sqlite.step_results.count)
    }

    func test_whenStatementHasNoColumns_thenReturns() throws {
        try givenResultSet()
        sqlite.column_count_result = 0
        XCTAssertTrue(rs.isColumnsEmpty)
        XCTAssertNotNil(sqlite.column_count_in_pStmt)
    }

    func test_resultSetColumnCount() throws {
        try givenResultSet()
        sqlite.column_count_result = 15
        XCTAssertEqual(rs.columnCount, 15)
    }

    func test_resultSet_columnValues() throws {
        try givenResultSet()

        sqlite.column_type_result = CSQLite3.SQLITE_TEXT
        sqlite.column_count_result = 3
        sqlite.column_text_result = "some"
        sqlite.column_bytes_result = Int32("some".cString(using: .utf8)!.count)
        XCTAssertEqual(rs.string(at: 2), "some")

        sqlite.column_type_result = CSQLite3.SQLITE_NULL
        XCTAssertNil(rs.string(at: 2))
        XCTAssertNil(rs.int(at: 2))
        XCTAssertNil(rs.double(at: 2))
        XCTAssertNil(rs.data(at: 2))

        sqlite.column_type_result = CSQLite3.SQLITE_INTEGER
        sqlite.column_int64_result = Int64(1)
        XCTAssertEqual(rs.int(at: 1), 1)

        sqlite.column_type_result = CSQLite3.SQLITE_FLOAT
        sqlite.column_double_result = 5.3
        XCTAssertEqual(rs.double(at: 0) ?? -1, 5.3, accuracy: 0.001)

        let data = Data(repeating: 3, count: 64)
        sqlite.column_type_result = CSQLite3.SQLITE_BLOB
        sqlite.column_blob_result = data
        sqlite.column_bytes_result = Int32(data.count)
        XCTAssertEqual(rs.data(at: 0), data)
    }

    func test_whenReturnsRow_thenResetsQuery() throws {
        try givenPreparedStatement()
        sqlite.step_results = [CSQLite3.SQLITE_ROW]
        try stmt.execute()
        XCTAssertNotNil(sqlite.reset_in_pStmt)
    }

    func test_whenReturns2Rows_thenCanAdvance2Times() throws {
        try givenPreparedStatement()
        sqlite.step_results = [CSQLite3.SQLITE_ROW, // called by execute()
            CSQLite3.SQLITE_ROW, // advanceToNextRow()
            CSQLite3.SQLITE_ROW,
            CSQLite3.SQLITE_DONE]
        guard let rs = try stmt.execute() else { throw Error.resultSetMissing }
        XCTAssertTrue(try rs.advanceToNextRow())
        XCTAssertTrue(try rs.advanceToNextRow())
        XCTAssertFalse(try rs.advanceToNextRow())
    }

    func test_whenOutsideOfExplicitTransactionAndBusyDuringAdvancing_thenRetries() throws {
        try givenPreparedStatement()
        sqlite.get_autocommit_result = 1
        sqlite.step_results = [CSQLite3.SQLITE_ROW, // called by execute()
            CSQLite3.SQLITE_ROW, // advanceToNextRow()
            CSQLite3.SQLITE_BUSY,
            CSQLite3.SQLITE_BUSY,
            CSQLite3.SQLITE_ROW,
            CSQLite3.SQLITE_DONE]
        guard let rs = try stmt.execute() else { throw Error.resultSetMissing }
        XCTAssertTrue(try rs.advanceToNextRow())
        XCTAssertTrue(try rs.advanceToNextRow())
        XCTAssertFalse(try rs.advanceToNextRow())
    }

    func test_statement_setParameters() throws {
        try givenPreparedStatement()

        sqlite.bind_text_result = CSQLite3.SQLITE_OK
        try stmt.set("text", at: 1)
        XCTAssertEqual(sqlite.bind_text_in_zValue, "text")
        XCTAssertNotNil(sqlite.bind_text_in_destructor)

        sqlite.bind_text_result = CSQLite3.SQLITE_MISUSE
        let message = SQLiteDatabase.errorMessage(from: CSQLite3.SQLITE_MISUSE, sqlite, sqlite.open_pointer_result)
        assertThrows(try stmt.set("text", at: 1), SQLiteDatabase.Error.failedToSetStatementParameter(message))

        sqlite.bind_text_result = CSQLite3.SQLITE_RANGE
        assertThrows(try stmt.set("text", at: 2), SQLiteDatabase.Error.statementParameterIndexOutOfRange)

        sqlite.bind_blob_result = CSQLite3.SQLITE_OK
        let data = Data(repeating: 1, count: 32)
        try stmt.set(data, at: 1)
        XCTAssertEqual(sqlite.bind_blob_in_zValue, data)
        XCTAssertNotNil(sqlite.bind_blob_in_destructor)

        sqlite.bind_int64_result = CSQLite3.SQLITE_OK
        try stmt.set(1, at: 1)
        XCTAssertEqual(sqlite.bind_int64_in_zValue, 1)

        sqlite.bind_double_result = CSQLite3.SQLITE_OK
        try stmt.set(1.2, at: 2)
        XCTAssertEqual(sqlite.bind_double_in_zValue, 1.2)

        sqlite.bind_null_result = CSQLite3.SQLITE_OK
        try stmt.setNil(at: 3)
        XCTAssertEqual(sqlite.bind_null_in_index, 3)

        sqlite.bind_text_result = CSQLite3.SQLITE_OK
        sqlite.bind_parameter_index_in_zName = nil
        try stmt.set("text", forKey: "key")
        XCTAssertEqual(sqlite.bind_parameter_index_in_zName, "key")

        sqlite.bind_blob_result = CSQLite3.SQLITE_OK
        sqlite.bind_parameter_index_in_zName = nil
        try stmt.set(data, forKey: "key")
        XCTAssertEqual(sqlite.bind_parameter_index_in_zName, "key")

        sqlite.bind_parameter_index_in_zName = nil
        try stmt.set(1, forKey: "key")
        XCTAssertEqual(sqlite.bind_parameter_index_in_zName, "key")

        sqlite.bind_parameter_index_in_zName = nil
        try stmt.set(1.2, forKey: "key")
        XCTAssertEqual(sqlite.bind_parameter_index_in_zName, "key")

        sqlite.bind_parameter_index_in_zName = nil
        try stmt.setNil(forKey: "key")
        XCTAssertEqual(sqlite.bind_parameter_index_in_zName, "key")
    }

    func test_whenStatementExecuted_thenBindingThrows() throws {
        try givenSuccessfullyExecutedStatement()
        assertThrows(try stmt.set(0, at: 1), SQLiteDatabase.Error.attemptToBindExecutedStatement)
        assertThrows(try stmt.set(Data(), at: 1), SQLiteDatabase.Error.attemptToBindExecutedStatement)
        assertThrows(try stmt.set(1.1, at: 1), SQLiteDatabase.Error.attemptToBindExecutedStatement)
        assertThrows(try stmt.set("text", at: 1), SQLiteDatabase.Error.attemptToBindExecutedStatement)
        assertThrows(try stmt.setNil(at: 1), SQLiteDatabase.Error.attemptToBindExecutedStatement)
        assertThrows(try stmt.set(0, forKey: "key"), SQLiteDatabase.Error.attemptToBindExecutedStatement)
        assertThrows(try stmt.set(Data(), forKey: "key"), SQLiteDatabase.Error.attemptToBindExecutedStatement)
        assertThrows(try stmt.set(1.1, forKey: "key"), SQLiteDatabase.Error.attemptToBindExecutedStatement)
        assertThrows(try stmt.set("text", forKey: "key"), SQLiteDatabase.Error.attemptToBindExecutedStatement)
        assertThrows(try stmt.setNil(forKey: "key"), SQLiteDatabase.Error.attemptToBindExecutedStatement)
    }

    func test_whenStatementFinalized_thenBindingThrows() throws {
        try givenNotExecutedFinalizedStatement()
        assertThrows(try stmt.set(0, at: 1), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
        assertThrows(try stmt.set(Data(), at: 1), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
        assertThrows(try stmt.set(1.1, at: 1), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
        assertThrows(try stmt.set("text", at: 1), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
        assertThrows(try stmt.setNil(at: 1), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
        assertThrows(try stmt.set(0, forKey: "key"), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
        assertThrows(try stmt.set(Data(), forKey: "key"), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
        assertThrows(try stmt.set(1.1, forKey: "key"), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
        assertThrows(try stmt.set("text", forKey: "key"), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
        assertThrows(try stmt.setNil(forKey: "key"), SQLiteDatabase.Error.attemptToBindFinalizedStatement)
    }

    func test_lastErrorMessage() throws {
        try givenConnection()
        sqlite.errmsg_result = "ERROR"
        XCTAssertEqual(conn.lastErrorMessage(), "ERROR")
    }

    func test_correctErrorCode() {
        XCTAssertEqual(CSQLite3.SQLITE_AUTH, 23)
    }

}

extension SQLiteDatabaseTests {

    private func givenNotExecutedFinalizedStatement() throws {
        try givenPreparedStatement()
        stmt.finalize()
    }

    private func givenSuccessfullyExecutedStatement() throws {
        try givenPreparedStatement()
        sqlite.step_results = [CSQLite3.SQLITE_DONE]
        _ = try stmt.execute()
    }

    private func givenPreparedStatement(_ sql: String = "some") throws {
        try givenConnection()
        sqlite.prepare_out_ppStmt = opaquePointer()
        guard let stmt = try conn.prepare(statement: sql) as? SQLiteStatement else {
            throw Error.unexpectedStatement
        }
        self.stmt = stmt
    }

    private func givenClosedConnection() throws {
        try givenConnection()
        try db.close(conn)
    }

    private func givenConnection() throws {
        try db.create()
        sqlite.open_pointer_result = opaquePointer()
        guard let conn = try db.connection() as? SQLiteConnection else {
            throw Error.unexpectedConnection
        }
        self.conn = conn
    }

    private func givenResultSet() throws {
        try givenPreparedStatement()
        sqlite.step_results = [CSQLite3.SQLITE_ROW]
        guard let rs = try stmt.execute() as? SQLiteResultSet else { throw Error.resultSetMissing }
        self.rs = rs
    }

    func opaquePointer() -> OpaquePointer {
        return String(repeating: "a", count: Int.random(in: 1...10)).withCString {
            ptr -> OpaquePointer in OpaquePointer(ptr)
        }
    }

    func assertThrows<T, E: Swift.Error & Hashable>(_ expression: @autoclosure () throws -> T,
                                                    _ error: E,
                                                    file: StaticString = #file,
                                                    line: UInt = #line,
                                                    function: StaticString = #function) {
        XCTAssertThrowsError(try expression(), file: file, line: line) {
            XCTAssertEqual($0 as? E, error, file: file, line: line)
        }
    }

}
