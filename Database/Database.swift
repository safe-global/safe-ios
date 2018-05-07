//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol Database {

    var exists: Bool { get }
    func create() throws
    func destroy() throws
    func connection() throws -> Connection
    func close(_ connection: Connection) throws

}

public protocol Connection {

    func prepare(statement: String) throws -> Statement
    func lastErrorMessage() -> String?

}

public protocol Statement {

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

public protocol ResultSet {

    func advanceToNextRow() throws -> Bool
    func string(at index: Int) -> String?
    func int(at index: Int) -> Int?
    func double(at index: Int) -> Double?
    func data(at index: Int) -> Data?

}

public extension Database {

    typealias CreateStatementClosure = (Connection) throws -> Statement

    func executeUpdate(sql: String) throws {
        try executeUpdate { conn in
            try conn.prepare(statement: sql)
        }
    }

    func executeUpdate(_ createStatement: CreateStatementClosure) throws {
        let conn = try connection()
        let stmt = try createStatement(conn)
        try stmt.execute()
        try close(conn)
    }

    func executeQuery<T>(sql: String, resultMap: (ResultSet) throws -> T?) -> T? {
        return executeQuery(resultMap: resultMap) { conn in
            try conn.prepare(statement: sql)
        }
    }

    func executeQuery<T>(resultMap: (ResultSet) throws -> T?, _ createStatement: CreateStatementClosure) -> T? {
        do {
            let conn = try connection()
            defer { try? close(conn) }
            let stmt = try createStatement(conn)
            if let rs = try stmt.execute(), let value = try resultMap(rs) {
                return value
            }
        } catch let e {
            preconditionFailure("Unexpected error: \(e)")
        }
        return nil
    }

}
