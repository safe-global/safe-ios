//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public struct TableSchema {

    public struct Field {

        public var name: String
        public var declaration: String

        public init(_ name: String) {
            self.name = name
            self.declaration = ""
        }

        public init(sql: String) {
            let components = sql.components(separatedBy: " ")
            self.name = components[0]
            self.declaration = sql
        }

    }

    public var tableName: String
    public var fields: [Field]
    public var primaryKey: Field {
        return fields.first { $0.declaration.uppercased().contains("PRIMARY KEY") }!
    }

    public init(_ name: String, _ fields: [Field]) {
        self.tableName = name
        self.fields = fields
    }

    public init(_ name: String, fields: [String]) {
        self.tableName = name
        self.fields = fields.map { Field(sql: $0) }
    }

    public init(_ name: String, _ varArgs: String...) {
        self.init(name, fields: varArgs)
    }

    public var createTableSQL: String {
        return "CREATE TABLE IF NOT EXISTS \(tableName) (\(fieldDeclarationList));"
    }

    public var insertSQL: String {
        return "INSERT OR REPLACE INTO \(tableName) VALUES (\(fieldAnonymousParameterList));"
    }

    public var deleteSQL: String {
        return "DELETE FROM \(tableName) WHERE \(primaryKey.name) = ?;"
    }

    public var findFirstSQL: String {
        return "SELECT \(fieldNameList) FROM \(tableName) ORDER BY rowid LIMIT 1;"
    }

    public var findByPrimaryKeySQL: String {
        return "SELECT \(fieldNameList) FROM \(tableName) WHERE \(primaryKey.name) = ? ORDER BY rowid LIMIT 1;"
    }

    public var findAllSQL: String {
        return "SELECT \(fieldNameList) FROM \(tableName);"
    }

    public var fieldDeclarationList: String {
        return list(of: fields.map { $0.declaration })
    }

    public var fieldNameList: String {
        return list(of: fields.map { $0.name })
    }

    public var fieldAnonymousParameterList: String {
        return list(of: fields.map { _ in "?" })
    }

    public func list(of values: [String]) -> String {
        return values.joined(separator: ", ")
    }

}
