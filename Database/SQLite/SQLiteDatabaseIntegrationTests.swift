//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Database

class SQLiteDatabaseIntegrationTests: XCTestCase {

    fileprivate func newDB() -> SQLiteDatabase {
        return SQLiteDatabase(name: "IntegrationTestDb",
                              fileManager: FileManager.default,
                              sqlite: CSQLite3(),
                              bundleId: "testBundle")
    }

    func test_create() throws {
        let db = newDB()
        try db.create()
        try db.destroy()
    }

    func test_createTableQuery() throws {
        let db = newDB()
        try db.create()
        let conn = try db.connection()
        let stmt = try conn.prepare(statement: "CREATE TABLE tbl_test (id INTEGER PRIMARY KEY, val TEXT);")
        try stmt.execute()
        try db.destroy()
    }

    func test_alterQuery() throws {
        let db = newDB()
        try db.destroy()
        try db.create()
        let conn = try db.connection()
        let stmt = try conn.prepare(statement: "CREATE TABLE tbl_test (id INTEGER PRIMARY KEY, val TEXT);")
        try stmt.execute()
        let stmt1 = try conn.prepare(statement: "ALTER TABLE tbl_test ADD tst DOUBLE;")
        try stmt1.execute()
        try db.destroy()
    }

    func test_insertRow() throws {
        let db = newDB()
        try db.destroy()
        try db.create()
        let conn = try db.connection()
        let stmt = try conn.prepare(statement: "CREATE TABLE tbl_test (id INTEGER PRIMARY KEY, val TEXT);")
        try stmt.execute()
        let stmt1 = try conn.prepare(statement: "INSERT INTO tbl_test VALUES (1, 'test');")
        try stmt1.execute()
        try db.destroy()
    }

    struct Test: Hashable {
        var id: Int
        var val: String
    }

    func test_query() throws {
        let db = newDB()
        try db.destroy()
        try db.create()
        let conn = try db.connection()
        let stmt = try conn.prepare(statement: "CREATE TABLE tbl_test (id INTEGER PRIMARY KEY, val TEXT);")
        try stmt.execute()
        let stmt1 = try conn.prepare(statement: "INSERT INTO tbl_test VALUES (1, 'test');")
        try stmt1.execute()
        let stmt2 = try conn.prepare(statement: "SELECT id, val FROM tbl_test;")
        if let rs = try stmt2.execute() {
            var results = [Test]()
            while try rs.advanceToNextRow() {
                results.append(Test(id: rs.int(at: 0) ?? -1, val: rs.string(at: 1) ?? "NULL"))
            }
            XCTAssertEqual(results, [Test(id: 1, val: "test")])
        } else {
            XCTFail("Results are missing")
        }
        try db.destroy()
    }

    func test_transaction_commit() throws {
        let db = newDB()
        try db.destroy()
        try db.create()
        let conn = try db.connection()
        let stmt = try conn.prepare(statement: "BEGIN;")
        try stmt.execute()
        let stmt0 = try conn.prepare(statement: "CREATE TABLE tbl_test (id INTEGER PRIMARY KEY, val TEXT);")
        try stmt0.execute()
        let stmt1 = try conn.prepare(statement: "INSERT INTO tbl_test VALUES (1, 'test');")
        try stmt1.execute()
        let stmt2 = try conn.prepare(statement: "SELECT id, val FROM tbl_test;")
        try stmt2.execute()
        let stmt3 = try conn.prepare(statement: "COMMIT;")
        try stmt3.execute()
        try db.destroy()
    }

    func test_transaction_rollback() throws {
        let db = newDB()
        try db.destroy()
        try db.create()
        let conn = try db.connection()
        let stmt = try conn.prepare(statement: "BEGIN;")
        try stmt.execute()
        let stmt0 = try conn.prepare(statement: "CREATE TABLE tbl_test (id INTEGER PRIMARY KEY, val TEXT);")
        try stmt0.execute()
        let stmt1 = try conn.prepare(statement: "INSERT INTO tbl_test VALUES (1, 'test');")
        try stmt1.execute()
        let stmt2 = try conn.prepare(statement: "ROLLBACK;")
        try stmt2.execute()
        XCTAssertThrowsError(try conn.prepare(statement: "SELECT id, val FROM tbl_test;"))
        try db.destroy()
    }

    func test_whenOneConnectionIsWritingAndOtherIsReading_thenOtherIsBlockingUntilWriteFinished() {
        do {
            let db = newDB()
            try db.destroy()
            try db.create()
            try db.execute(sql: "CREATE TABLE tbl_test (id INTEGER PRIMARY KEY, val TEXT);")
            let exp = expectation(description: "wait")
            DispatchQueue.global().async {
                do {
                    for i in (0..<10) {
                        try db.execute(sql: "INSERT INTO tbl_test VALUES (?, 'test');", bindings: [i])
                    }
                    exp.fulfill()
                } catch let error {
                    DispatchQueue.main.async {
                        XCTFail("Failure in background thread: \(error)")
                    }
                }
            }
            for _ in (0..<10) {
                try db.execute(sql: "SELECT id, val FROM tbl_test;")
            }
            waitForExpectations(timeout: 5, handler: nil)
        } catch let error {
            XCTFail("Failed with error: \(error)")
        }
    }

}
