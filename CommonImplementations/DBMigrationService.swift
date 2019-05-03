//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Database
import Common

public class MigrationID: BaseID {}

open class Migration: IdentifiableEntity<MigrationID> {

    public required init(_ id: String) {
        super.init(id: MigrationID(id))
    }

    open func setUp(connection: Connection) throws {}

}

public class DBMigrationRepository: DBEntityRepository<Migration, MigrationID> {

    public private(set) var migrations = [Migration]()

    public override var table: TableSchema {
        return .init("tbl_migrations", "id TEXT NOT NULL PRIMARY KEY")
    }

    public override func insertionBindings(_ object: Migration) -> [SQLBindable?] {
        return bindable([object.id])
    }

    public override func objectFromResultSet(_ rs: ResultSet) -> Migration? {
        guard let id: String = rs["id"] else { return nil }
        return Migration(id)
    }

    public func findLatest() -> Migration? {
        let sql = """
        SELECT \(table.fieldNameList)
        FROM \(table.tableName)
        ORDER BY \(table.primaryKey.name) DESC
        LIMIT 1;
        """
        return try! first(of: db.execute(sql: sql, resultMap: objectFromResultSet))
    }

    public func register(migration: Migration) {
        migrations.append(migration)
    }

    public func unregister(migration: Migration) {
        if let index = migrations.firstIndex(of: migration) {
            migrations.remove(at: index)
        }
    }

    public func pendingMigrations() -> [Migration] {
        let migrations = self.migrations.sorted { $0.id.id < $1.id.id }
        if let latestInDB = findLatest(), let index = migrations.firstIndex(of: latestInDB) {
            if index < migrations.count - 1 {
                return Array(migrations[index + 1..<migrations.count])
            } else {
                return []
            }
        }
        return migrations
    }

    public func executeInTransaction(_ closure: (Connection) throws -> Void) throws {
        let connection = try db.connection()
        defer { try? db.close(connection) }
        try connection.execute(sql: "BEGIN;")
        do {
            try closure(connection)
            try connection.execute(sql: "COMMIT;")
        } catch let error {
            try? connection.execute(sql: "ROLLBACK;")
            throw error
        }
    }

    public func save(_ object: Migration, connection: Connection) {
        try! connection.execute(sql: table.insertSQL, bindings: insertionBindings(object))
    }

}

public class DBMigrationService {

    private let repository: DBMigrationRepository

    public init(repository: DBMigrationRepository) {
        self.repository = repository
    }

    public func register(_ migrations: [Migration]) {
        migrations.forEach { register($0) }
    }

    public func register(_ migration: Migration) {
        repository.register(migration: migration)
    }

    public func migrate() throws {
        let pendingMigrations = repository.pendingMigrations()
        guard !pendingMigrations.isEmpty else { return }
        try repository.executeInTransaction { connection in
            for migration in pendingMigrations {
                try migration.setUp(connection: connection)
                repository.save(migration, connection: connection)
            }
        }
    }

    public func skipMigrationsBeforeAndIncluding(_ migration: Migration) throws {
        try repository.executeInTransaction { connection in
            repository.save(migration, connection: connection)
        }
    }

}
