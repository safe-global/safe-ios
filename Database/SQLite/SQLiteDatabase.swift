//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public class SQLiteDatabase: Database, Assertable {

    public let name: String
    public var exists: Bool {
        try? buildURL()
        guard let url = self.url else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    public var url: URL!
    private let fileManager: FileManager
    private let sqlite: CSQLite3
    private let bundleIdentifier: String
    // SQLite's default mode is when connections are not shared across threads
    // that's why we use theadDictionary to store connections for each thread separately.
    private var connections: [SQLiteConnection] {
        get {
            let nsDict = Thread.current.threadDictionary
            return nsDict["sqlite_connections"] as? [SQLiteConnection] ?? []
        }
        set {
            let nsDict = Thread.current.threadDictionary
            nsDict["sqlite_connections"] = newValue
        }
    }

    public enum Error: Hashable, LocalizedError {
        case applicationSupportDirNotFound
        case bundleIdentifierNotFound
        case databaseAlreadyExists
        case failedToCreateDatabase
        case databaseDoesNotExist
        case invalidSQLiteVersion
        case failedToOpenDatabase
        case databaseBusy
        case connectionIsNotOpened
        case invalidSQLStatement(String)
        case attemptToExecuteFinalizedStatement
        case connectionIsAlreadyClosed
        case invalidConnection
        case statementWasAlreadyExecuted
        case runtimeError(String)
        case invalidStatementState
        case transactionMustBeRolledBack
        case invalidStringBindingValue
        case failedToSetStatementParameter
        case statementParameterIndexOutOfRange
        case invalidStatementKeyValue
        case attemptToBindExecutedStatement
        case attemptToBindFinalizedStatement
    }

    public init(name: String, fileManager: FileManager, sqlite: CSQLite3, bundleId: String) {
        self.name = name
        self.fileManager = fileManager
        self.sqlite = sqlite
        self.bundleIdentifier = bundleId
        self.connections = []
    }

    public func create() throws {
        try buildURL()
        try assertFalse(fileManager.fileExists(atPath: url.path), Error.databaseAlreadyExists)
        let attributes = [FileAttributeKey.protectionKey: FileProtectionType.completeUnlessOpen]
        let didCreate = fileManager.createFile(atPath: url.path, contents: nil, attributes: attributes)
        if !didCreate {
            throw Error.failedToCreateDatabase
        }
    }

    public func connection() throws -> Connection {
        try buildURL()
        try assertTrue(fileManager.fileExists(atPath: url.path), Error.databaseDoesNotExist)
        let libVersion = Version(String(cString: sqlite.sqlite3_libversion()))
        let headerVersion = Version(sqlite.SQLITE_VERSION)
        try assertEqual(libVersion.major, headerVersion.major, Error.invalidSQLiteVersion)
        if libVersion == headerVersion {
            let libSourceId = String(cString: sqlite.sqlite3_sourceid()).prefix(80)
            let headerSourceId = sqlite.SQLITE_SOURCE_ID.prefix(80)
            try assertEqual(libSourceId, headerSourceId, Error.invalidSQLiteVersion)
            let libVersionNumber = sqlite.sqlite3_libversion_number()
            let headerVersionNumber = sqlite.SQLITE_VERSION_NUMBER
            try assertEqual(libVersionNumber, headerVersionNumber, Error.invalidSQLiteVersion)
        }
        let connection = SQLiteConnection(sqlite: sqlite)
        try connection.open(url: url)
        connections.append(connection)
        return connection
    }

    private struct Version: Equatable {

        let major: String
        let minor: String
        let patch: String

        init(_ str: String) {
            var parts = str.components(separatedBy: ".")
            if parts.count == 3 {
                (major, minor, patch) = (parts[0], parts[1], parts[2])
            } else if parts.count == 2 {
                (major, minor, patch) = (parts[0], parts[1], "")
            } else {
                (major, minor, patch) = (str, "", "")
            }
        }

    }

    public func close(_ connection: Connection) throws {
        guard let connection = connection as? SQLiteConnection else {
            throw SQLiteDatabase.Error.invalidConnection
        }
        try connection.close()
        if let index = connections.index(where: { $0 === connection }) {
            connections.remove(at: index)
        }
    }

    public func destroy() throws {
        try connections.forEach { try $0.close() }
        connections.removeAll()
        try? buildURL()
        guard let url = url else { return }
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private func buildURL() throws {
        if url != nil { return }
        let appSupportDir = try fileManager.url(for: .applicationSupportDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
        try assertTrue(fileManager.fileExists(atPath: appSupportDir.path), Error.applicationSupportDirNotFound)
        let bundleDir = appSupportDir.appendingPathComponent(bundleIdentifier, isDirectory: true)
        if !fileManager.fileExists(atPath: bundleDir.path) {
            try fileManager.createDirectory(at: bundleDir, withIntermediateDirectories: false, attributes: nil)
        }
        self.url = bundleDir.appendingPathComponent(name).appendingPathExtension("db")
    }

}
