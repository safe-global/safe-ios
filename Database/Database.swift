//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol Database: class {

    var exists: Bool { get }
    func create() throws
    func destroy() throws
    func connection() throws -> Connection
    func close(_ connection: Connection) throws

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
