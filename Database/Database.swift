//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol Database: class {

    /// True if the database
    var exists: Bool { get }

    /// Creates the database. Throws error if the database already exists.
    /// May throw error if unable to create the database for some other reason.
    ///
    /// - Throws: May throw error if some problem encountered.
    func create() throws

    /// Deletes the database. All active connections are closed automatically before destroying.
    ///
    /// - Throws: if unable to destroy the database.
    func destroy() throws

    /// Creates new connection to the database and opens it. The database must exist, otherwise error is thrown.
    ///
    /// - Returns: Initialized and opened connection.
    /// - Throws: error thrown if database does not exist or some problem creating connection encountered.
    func connection() throws -> Connection

    /// Closes opened connection that was created by `connection()` method. If the connection is already closed,
    /// the method throws error.
    ///
    /// - Parameter connection: connection that was created before.
    /// - Throws: if connection was closed, method throws error. May throw other error if closing failed.
    func close(_ connection: Connection) throws

    /// Executes arbitrary SQL statement, binding values from `bindings` and `dict` arguments to it.
    /// This method is meant for update queries.
    ///
    /// See `execute(sql:bindings:dict:resultMap:)` for executing SQL select queries that return result.
    ///
    /// - Parameters:
    ///   - sql: SQL string to execute
    ///   - bindings: Array of optional bindable values to bind with SQL statement by array index.
    ///   - dict: Dictionary of bindable values to bind with SQL statement by keys.
    /// - Returns: result of the SQL statement is ignored.
    /// - Throws: may throw error if there is a problem with SQL statement or with the database.
    func execute(sql: String, bindings: [SQLBindable?], dict: [String: SQLBindable?]) throws

    func execute<T>(sql: String,
                    bindings: [SQLBindable?],
                    dict: [String: SQLBindable?],
                    resultMap: (ResultSet) throws -> T?) throws -> [T?]

}

public protocol Connection: class {

    func prepare(statement: String) throws -> Statement
    func lastErrorMessage() -> String?

}

public protocol Statement: class {

    func set(_ value: String, at index: Int) throws
    func set(_ value: Data, at index: Int) throws
    func set(_ value: Int, at index: Int) throws
    func set(_ value: Double, at index: Int) throws
    func setNil(at index: Int) throws

    func set(_ value: String, forKey key: String) throws
    func set(_ value: Data, forKey key: String) throws
    func set(_ value: Int, forKey key: String) throws
    func set(_ value: Double, forKey key: String) throws
    func setNil(forKey key: String) throws

    @discardableResult
    func execute() throws -> ResultSet?

}

public protocol ResultSet: class {

    func advanceToNextRow() throws -> Bool
    func string(at index: Int) -> String?
    func int(at index: Int) -> Int?
    func double(at index: Int) -> Double?
    func data(at index: Int) -> Data?

}

public protocol SQLBindable {}

extension Int: SQLBindable {}
extension Double: SQLBindable {}
extension String: SQLBindable {}
extension Data: SQLBindable {}


public extension Statement {

    func bind(_ bindings: [SQLBindable?]) throws {
        try bindings.enumerated().map { ($0 + 1, $1) }.forEach { index, value in
            guard let value = value else {
                try setNil(at: index)
                return
            }
            switch value {
            case let int as Int: try set(int, at: index)
            case let double as Double: try set(double, at: index)
            case let string as String: try set(string, at: index)
            case let data as Data: try set(data, at: index)
            default: preconditionFailure("Unrecognized SQLBindable type at index \(index - 1)")
            }
        }
    }

    func bind(_ bindings: [String: SQLBindable?]) throws {
        try bindings.forEach { key, value in
            guard let value = value else {
                try setNil(forKey: key)
                return
            }
            switch value {
            case let int as Int: try set(int, forKey: key)
            case let double as Double: try set(double, forKey: key)
            case let string as String: try set(string, forKey: key)
            case let data as Data: try set(data, forKey: key)
            default: preconditionFailure("Unrecognized SQLBindable type for key \(key)")
            }
        }
    }

}

public extension Database {

    func execute(sql: String,
                 bindings: [SQLBindable?] = [],
                 dict: [String: SQLBindable?] = [:]) throws {
        let map: (ResultSet) throws -> Void? = { _ in return nil }
        _ = try self.execute(sql: sql, bindings: bindings, dict: dict, resultMap: map)
    }

    func execute<T>(sql: String,
                    bindings: [SQLBindable?] = [],
                    dict: [String: SQLBindable?] = [:],
                    resultMap: (ResultSet) throws -> T?) throws -> [T?] {
        let conn = try connection()
        defer { try? close(conn) }
        let stmt = try conn.prepare(statement: sql)
        try stmt.bind(bindings)
        try stmt.bind(dict)
        guard let rs = try stmt.execute() else { return [] }
        var result = [T?]()
        while try rs.advanceToNextRow() {
            try result.append(resultMap(rs))
        }
        return result
    }

}
