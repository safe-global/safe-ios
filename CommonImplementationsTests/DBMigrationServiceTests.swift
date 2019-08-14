//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import XCTest
import CommonImplementations
import Database

class DBMigrationServiceTests: XCTestCase {

    var db: SQLiteDatabase!
    var repository: DBMigrationRepository!
    var service: DBMigrationService!

    override func setUp() {
        super.setUp()
        db = SQLiteDatabase(name: String(reflecting: self),
                            fileManager: FileManager.default,
                            sqlite: CSQLite3(),
                            bundleId: String(reflecting: self))
        try? db.destroy()
        try! db.create()

        repository = DBMigrationRepository(db: db)
        repository.setUp()

        service = DBMigrationService(repository: repository)
    }

    override func tearDown() {
        super.tearDown()
        try? db.destroy()
    }

    func test_runsMigrationsOnlyOnce() throws {
        let migration = FakeMigration()
        service.register(migration)
        XCTAssertEqual(migration.runCount, 0)
        try service.migrate()
        XCTAssertEqual(migration.runCount, 1)
        try service.migrate()
        XCTAssertEqual(migration.runCount, 1)
    }

    func test_runsOneMigrationToCreateNewTable() throws {
        let migration = CreateUserTableMigration()
        service.register(migration)
        try service.migrate()
        XCTAssertEqual(repository.findLatest(), migration)
        let sqls = try repository.db.execute(sql: "SELECT sql FROM sqlite_master;") { rs -> String? in
            rs["sql"]
        }.compactMap { $0 }
        XCTAssertTrue(sqls.contains { $0.contains("tbl_users") }, "Created table not found")
    }

    func test_runsMultipleMigrations() {
        createAccountsTable()

        // These are migrations that do not require advanced table changes (add column and rename table).
        service.register(AddUpdatedAtColumnToAccount())
        service.register(RenameAccountTable())
        try! service.migrate()

        // Other changes to a table require re-creating the table and migrating the data.
        // SQLite v3.24.0 on iOS 12 does not support RENAME COLUMN TO syntax (added in v3.25.0)
        service.register(RemoveTimestampChangeBalanceTypeAccount())
        try! service.migrate()

        service.register(RenameAccountTableAgain())
        try! service.migrate()

        let results = try! db.execute(sql: "SELECT id, balance FROM tbl_accounts;") { rs -> Account? in
            guard let id: String = rs["id"], let balance: Int = rs["balance"] else { return nil }
            return Account(id: id, balance: balance)
            }.compactMap { $0 }
        XCTAssertEqual(results, [Account(id: "a", balance: 1),
                                 Account(id: "b", balance: 2),
                                 Account(id: "c", balance: 3)])
    }

    func test_skipsMigrations() {
        createAccountsTable()
        try! service.skipMigrationsBeforeAndIncluding(RenameAccountTable())
        service.register(AddUpdatedAtColumnToAccount())
        service.register(RenameAccountTable())
        service.register(Rename2AccountTable())
        try! service.migrate()

        let results = try! db.execute(sql: "SELECT id, balance FROM tbl_accounts2;") { rs -> Account? in
            guard let id: String = rs["id"], let balance: Int = rs["balance"] else { return nil }
            return Account(id: id, balance: balance)
            }.compactMap { $0 }
        XCTAssertEqual(results, [Account(id: "a", balance: 1),
                                 Account(id: "b", balance: 2),
                                 Account(id: "c", balance: 3)])
    }

    private func createAccountsTable() {
        let table = TableSchema("tbl_accounts",
                                "id TEXT NOT NULL PRIMARY KEY",
                                "balance TEXT")
        try! db.execute(sql: table.createTableSQL)
        try! db.execute(sql: table.insertSQL, bindings: ["a", "1"])
        try! db.execute(sql: table.insertSQL, bindings: ["b", "2"])
        try! db.execute(sql: table.insertSQL, bindings: ["c", "3"])
    }

}

fileprivate class FakeMigration: Migration {

    convenience init() {
        self.init("0000_fake_migration")
    }

    var runCount = 0
    override func setUp(connection: Connection) throws {
        runCount += 1
    }

}

fileprivate class CreateUserTableMigration: Migration {

    let schema = TableSchema("tbl_users", "id TEXT NOT NULL", "name TEXT NOT NULL")

    convenience init() {
        self.init("0001_create_user_table")
    }

    override func setUp(connection: Connection) throws {
        try connection.execute(sql: schema.createTableSQL)
    }

}

fileprivate struct Account: Equatable {
    var id: String
    var balance: Int
}

fileprivate class AddUpdatedAtColumnToAccount: Migration {

    convenience init() {
        self.init("0002_add_updated_at_column_to_account")
    }

    override func setUp(connection: Connection) throws {
        let sql = "ALTER TABLE tbl_accounts ADD updated_at TEXT;"
        try connection.execute(sql: sql)
    }

}

fileprivate class RenameAccountTable: Migration {

    convenience init() {
        self.init("0003_rename_account_table")
    }

    override func setUp(connection: Connection) throws {
        let sql = "ALTER TABLE tbl_accounts RENAME TO tbl_token_accounts;"
        try connection.execute(sql: sql)
    }

}

fileprivate class RemoveTimestampChangeBalanceTypeAccount: Migration {

    let oldTable = TableSchema("tbl_token_accounts",
                               "id TEXT NOT NULL PRIMARY KEY",
                               "balance TEXT",
                               "updated_at TEXT") // field will be dropped
    let newTable = TableSchema("new_tbl_token_accounts",
                               "id TEXT NOT NULL PRIMARY KEY",
                               "balance INTEGER") // the type has changed

    convenience init() {
        self.init("0004_remove_timestamp_change_balance_data_type_in_account")
    }

    override func setUp(connection: Connection) throws {
        try connection.execute(sql: newTable.createTableSQL)
        let migrateDataSQL = "INSERT INTO \(newTable.tableName) SELECT id, balance FROM \(oldTable.tableName);"
        try connection.execute(sql: migrateDataSQL)
        try connection.execute(sql: "DROP TABLE \(oldTable.tableName);")
        try connection.execute(sql: "ALTER TABLE \(newTable.tableName) RENAME TO \(oldTable.tableName);")
    }

}

fileprivate class RenameAccountTableAgain: Migration {

    convenience init() {
        self.init("0005_rename_account_table")
    }

    override func setUp(connection: Connection) throws {
        let sql = "ALTER TABLE tbl_token_accounts RENAME TO tbl_accounts;"
        try connection.execute(sql: sql)
    }

}

fileprivate class Rename2AccountTable: Migration {

    convenience init() {
        self.init("0006_rename_account_table")
    }

    override func setUp(connection: Connection) throws {
        let sql = "ALTER TABLE tbl_accounts RENAME TO tbl_accounts2;"
        try connection.execute(sql: sql)
    }

}
