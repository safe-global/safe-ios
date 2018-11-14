//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

/// `SQLiteDatabase` is used to create a database, connect to existing one, close and open connections, and destroy
/// existing database.
///
/// You initialize a database with a name, `CSQlite3` instance (wrapper over SQLite C interface), `FileManager` and
/// bundle identifier.
///
/// After that, you can create database if it does not exist, otherwise, you can start executing
/// queries or creating connections.
///
/// **Important**: If you created any connections with `SQLiteDatabase.connection()` method,
/// then remember to close them with `SQLiteDatabase.close(...)` method, otherwise underlying C objects will leak
/// and database may end up in undefined state.
public class SQLiteDatabase: Database, Assertable {

    /// The SQLite filename will have "db" extension with this `name`.
    public let name: String

    /// True if `name`.db file exists at `url` path.
    public var exists: Bool {
        try? buildURL()
        guard let url = self.url else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    /// Full file url of the database
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

    /// Errors that are thrown from SQLite* classes' methods.
    public enum Error: Hashable, LocalizedError {
        case applicationSupportDirNotFound
        case bundleIdentifierNotFound
        case databaseAlreadyExists
        case failedToCreateDatabase
        case databaseDoesNotExist
        case invalidSQLiteVersion
        case failedToOpenDatabase(String)
        case failedToCloseDatabase(String)
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
        case failedToSetStatementParameter(String)
        case statementParameterIndexOutOfRange
        case invalidStatementKeyValue
        case attemptToBindExecutedStatement
        case attemptToBindFinalizedStatement
    }

    static func errorMessage(from status: Int32, _ sqlite: CSQLite3, _ db: OpaquePointer?) -> String {
        guard let db = db,
            let cString = sqlite.sqlite3_errmsg(db),
            let message = String(cString: cString, encoding: .utf8) else {
                return "(unknown error code)"
        }
        return message
    }


    /// Initializes new `SQLiteDatabase` object with name, dependencies and bundleId string.
    ///
    /// - Parameters:
    ///   - name: The name will be used with ".db" extension to compose path to the database file.
    ///   - fileManager: The FileManager dependency to access file system.
    ///   - sqlite: The SQLite3 C API wrapper dependency.
    ///   - bundleId: The bundleId string used to create or use a subfolder in ApplicationSupport directory.
    public init(name: String, fileManager: FileManager, sqlite: CSQLite3, bundleId: String) {
        self.name = name
        self.fileManager = fileManager
        self.sqlite = sqlite
        self.bundleIdentifier = bundleId
        self.connections = []
    }

    /// Creates an empty database file.
    ///
    /// ## Discussion
    /// This method will create a `bundleId` directory inside ApplicationSupport directory if it does not exist.
    /// It will also create an empty file named `name`.db inside that directory.
    /// - Throws:
    ///     - `Error.applicationSupportDirNotFound` thrown if can't find ApplicationSupport directory in file system.
    ///     - `Error.databaseAlreadyExists` thrown if database file already exists.
    ///     - `Error.failedToCreateDatabase` if were unable to create empty database file.
    ///     - Any other errors from FileManager APIs may be thrown, if there was an error.
    public func create() throws {
        try buildURL()
        try assertFalse(fileManager.fileExists(atPath: url.path), Error.databaseAlreadyExists)
        let attributes = [FileAttributeKey.protectionKey: FileProtectionType.completeUnlessOpen]
        let didCreate = fileManager.createFile(atPath: url.path, contents: nil, attributes: attributes)
        if !didCreate {
            throw Error.failedToCreateDatabase
        }
    }

    /// Creates new `SQLiteConnection`, opens it and retains it.
    ///
    /// - Returns: new connection
    /// - Throws:
    ///     - `Error.databaseDoesNotExist` if database file is not there
    ///     - `Error.invalidSQLiteVersion` if the linked library's major version is different from headers version
    ///     - `Error.invalidSQLiteVersion` if linked library's and headers version equal but other version
    ///       variables, like source id and integer version number have different header and linked values.
    ///     - If `SQLiteConnection` opening throws error, it will be rethrown here.
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

    /// Closes open connection, created with `connection()` method. Connection must be still open. Releases retained
    /// object when connection is successfully closed.
    ///
    /// - Parameter connection: Previously opened connection.
    /// - Throws:
    ///     - `Error.invalidConnection` in case connection is not `SQLiteConnection`
    ///     - Any error thrown from `SQLiteConnection.close()` is rethrown.
    public func close(_ connection: Connection) throws {
        guard let connection = connection as? SQLiteConnection else {
            throw SQLiteDatabase.Error.invalidConnection
        }
        try connection.close()
        if let index = connections.index(where: { $0 === connection }) {
            connections.remove(at: index)
        }
    }

    /// Closes all opened connections, releases memory for them, and removes database filen.
    ///
    /// - Throws: Throws error if were unable to close any connection or unable to delete database file.
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
