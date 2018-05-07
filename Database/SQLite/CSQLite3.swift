//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import SQLite3

open class CSQLite3 {

    public init() {}

    open var SQLITE_VERSION: String { return SQLite3.SQLITE_VERSION }
    open var SQLITE_VERSION_NUMBER: Int32 { return SQLite3.SQLITE_VERSION_NUMBER }
    open var SQLITE_SOURCE_ID: String { return SQLite3.SQLITE_SOURCE_ID }

    public static var SQLITE_INTEGER: Int32 { return SQLite3.SQLITE_INTEGER }
    public static var SQLITE_FLOAT: Int32 { return SQLite3.SQLITE_FLOAT }
    public static var SQLITE_TEXT: Int32 { return SQLite3.SQLITE_TEXT }
    public static var SQLITE_BLOB: Int32 { return SQLite3.SQLITE_BLOB }
    public static var SQLITE_NULL: Int32 { return SQLite3.SQLITE_NULL }

    public static var SQLITE_OK: Int32 { return SQLite3.SQLITE_OK }
    public static var SQLITE_ERROR: Int32 { return SQLite3.SQLITE_ERROR }
    public static var SQLITE_INTERNAL: Int32 { return SQLite3.SQLITE_INTERNAL }
    public static var SQLITE_PERM: Int32 { return SQLite3.SQLITE_PERM }
    public static var SQLITE_ABORT: Int32 { return SQLite3.SQLITE_ABORT }
    public static var SQLITE_BUSY: Int32 { return SQLite3.SQLITE_BUSY }
    public static var SQLITE_LOCKED: Int32 { return SQLite3.SQLITE_LOCKED }
    public static var SQLITE_NOMEM: Int32 { return SQLite3.SQLITE_NOMEM }
    public static var SQLITE_READONLY: Int32 { return SQLite3.SQLITE_READONLY }
    public static var SQLITE_INTERRUPT: Int32 { return SQLite3.SQLITE_INTERRUPT }
    public static var SQLITE_IOERR: Int32 { return SQLite3.SQLITE_IOERR }
    public static var SQLITE_CORRUPT: Int32 { return SQLite3.SQLITE_CORRUPT }
    public static var SQLITE_NOTFOUND: Int32 { return SQLite3.SQLITE_NOTFOUND }
    public static var SQLITE_FULL: Int32 { return SQLite3.SQLITE_FULL }
    public static var SQLITE_CANTOPEN: Int32 { return SQLite3.SQLITE_CANTOPEN }
    public static var SQLITE_PROTOCOL: Int32 { return SQLite3.SQLITE_PROTOCOL }
    public static var SQLITE_EMPTY: Int32 { return SQLite3.SQLITE_EMPTY }
    public static var SQLITE_SCHEMA: Int32 { return SQLite3.SQLITE_SCHEMA }
    public static var SQLITE_TOOBIG: Int32 { return SQLite3.SQLITE_TOOBIG }
    public static var SQLITE_CONSTRAINT: Int32 { return SQLite3.SQLITE_CONSTRAINT }
    public static var SQLITE_MISMATCH: Int32 { return SQLite3.SQLITE_MISMATCH }
    public static var SQLITE_MISUSE: Int32 { return SQLite3.SQLITE_MISUSE }
    public static var SQLITE_NOLFS: Int32 { return SQLite3.SQLITE_NOLFS }
    public static var SQLITE_AUTH: Int32 { return SQLite3.SQLITE_AUTH }
    public static var SQLITE_FORMAT: Int32 { return SQLite3.SQLITE_FORMAT }
    public static var SQLITE_RANGE: Int32 { return SQLite3.SQLITE_RANGE }
    public static var SQLITE_NOTADB: Int32 { return SQLite3.SQLITE_NOTADB }
    public static var SQLITE_NOTICE: Int32 { return SQLite3.SQLITE_NOTICE }
    public static var SQLITE_WARNING: Int32 { return SQLite3.SQLITE_WARNING }
    public static var SQLITE_ROW: Int32 { return SQLite3.SQLITE_ROW }
    public static var SQLITE_DONE: Int32 { return SQLite3.SQLITE_DONE }

    public static var SQLITE_IOERR_READ: Int32 { return (SQLITE_IOERR | (1 << 8)) }
    public static var SQLITE_IOERR_SHORT_READ: Int32 { return (SQLITE_IOERR | (2 << 8)) }
    public static var SQLITE_IOERR_WRITE: Int32 { return (SQLITE_IOERR | (3 << 8)) }
    public static var SQLITE_IOERR_FSYNC: Int32 { return (SQLITE_IOERR | (4 << 8)) }
    public static var SQLITE_IOERR_DIR_FSYNC: Int32 { return (SQLITE_IOERR | (5 << 8)) }
    public static var SQLITE_IOERR_TRUNCATE: Int32 { return (SQLITE_IOERR | (6 << 8)) }
    public static var SQLITE_IOERR_FSTAT: Int32 { return (SQLITE_IOERR | (7 << 8)) }
    public static var SQLITE_IOERR_UNLOCK: Int32 { return (SQLITE_IOERR | (8 << 8)) }
    public static var SQLITE_IOERR_RDLOCK: Int32 { return (SQLITE_IOERR | (9 << 8)) }
    public static var SQLITE_IOERR_DELETE: Int32 { return (SQLITE_IOERR | (10 << 8)) }
    public static var SQLITE_IOERR_BLOCKED: Int32 { return (SQLITE_IOERR | (11 << 8)) }
    public static var SQLITE_IOERR_NOMEM: Int32 { return (SQLITE_IOERR | (12 << 8)) }
    public static var SQLITE_IOERR_ACCESS: Int32 { return (SQLITE_IOERR | (13 << 8)) }
    public static var SQLITE_IOERR_CHECKRESERVEDLOCK: Int32 { return (SQLITE_IOERR | (14 << 8)) }
    public static var SQLITE_IOERR_LOCK: Int32 { return (SQLITE_IOERR | (15 << 8)) }
    public static var SQLITE_IOERR_CLOSE: Int32 { return (SQLITE_IOERR | (16 << 8)) }
    public static var SQLITE_IOERR_DIR_CLOSE: Int32 { return (SQLITE_IOERR | (17 << 8)) }
    public static var SQLITE_IOERR_SHMOPEN: Int32 { return (SQLITE_IOERR | (18 << 8)) }
    public static var SQLITE_IOERR_SHMSIZE: Int32 { return (SQLITE_IOERR | (19 << 8)) }
    public static var SQLITE_IOERR_SHMLOCK: Int32 { return (SQLITE_IOERR | (20 << 8)) }
    public static var SQLITE_IOERR_SHMMAP: Int32 { return (SQLITE_IOERR | (21 << 8)) }
    public static var SQLITE_IOERR_SEEK: Int32 { return (SQLITE_IOERR | (22 << 8)) }
    public static var SQLITE_IOERR_DELETE_NOENT: Int32 { return (SQLITE_IOERR | (23 << 8)) }
    public static var SQLITE_IOERR_MMAP: Int32 { return (SQLITE_IOERR | (24 << 8)) }
    public static var SQLITE_IOERR_GETTEMPPATH: Int32 { return (SQLITE_IOERR | (25 << 8)) }
    public static var SQLITE_IOERR_CONVPATH: Int32 { return (SQLITE_IOERR | (26 << 8)) }
    public static var SQLITE_IOERR_VNODE: Int32 { return (SQLITE_IOERR | (27 << 8)) }
    public static var SQLITE_IOERR_AUTH: Int32 { return (SQLITE_IOERR | (28 << 8)) }
    public static var SQLITE_LOCKED_SHAREDCACHE: Int32 { return (SQLITE_LOCKED | (1 << 8)) }
    public static var SQLITE_BUSY_RECOVERY: Int32 { return (SQLITE_BUSY | (1 << 8)) }
    public static var SQLITE_BUSY_SNAPSHOT: Int32 { return (SQLITE_BUSY | (2 << 8)) }
    public static var SQLITE_CANTOPEN_NOTEMPDIR: Int32 { return (SQLITE_CANTOPEN | (1 << 8)) }
    public static var SQLITE_CANTOPEN_ISDIR: Int32 { return (SQLITE_CANTOPEN | (2 << 8)) }
    public static var SQLITE_CANTOPEN_FULLPATH: Int32 { return (SQLITE_CANTOPEN | (3 << 8)) }
    public static var SQLITE_CANTOPEN_CONVPATH: Int32 { return (SQLITE_CANTOPEN | (4 << 8)) }
    public static var SQLITE_CANTOPEN_DIRTYWAL: Int32 { return (SQLITE_CANTOPEN | (5 << 8)) }
    public static var SQLITE_CORRUPT_VTAB: Int32 { return (SQLITE_CORRUPT | (1 << 8)) }
    public static var SQLITE_READONLY_RECOVERY: Int32 { return (SQLITE_READONLY | (1 << 8)) }
    public static var SQLITE_READONLY_CANTLOCK: Int32 { return (SQLITE_READONLY | (2 << 8)) }
    public static var SQLITE_READONLY_ROLLBACK: Int32 { return (SQLITE_READONLY | (3 << 8)) }
    public static var SQLITE_READONLY_DBMOVED: Int32 { return (SQLITE_READONLY | (4 << 8)) }
    public static var SQLITE_ABORT_ROLLBACK: Int32 { return (SQLITE_ABORT | (2 << 8)) }
    public static var SQLITE_CONSTRAINT_CHECK: Int32 { return (SQLITE_CONSTRAINT | (1 << 8)) }
    public static var SQLITE_CONSTRAINT_COMMITHOOK: Int32 { return (SQLITE_CONSTRAINT | (2 << 8)) }
    public static var SQLITE_CONSTRAINT_FOREIGNKEY: Int32 { return (SQLITE_CONSTRAINT | (3 << 8)) }
    public static var SQLITE_CONSTRAINT_FUNCTION: Int32 { return (SQLITE_CONSTRAINT | (4 << 8)) }
    public static var SQLITE_CONSTRAINT_NOTNULL: Int32 { return (SQLITE_CONSTRAINT | (5 << 8)) }
    public static var SQLITE_CONSTRAINT_PRIMARYKEY: Int32 { return (SQLITE_CONSTRAINT | (6 << 8)) }
    public static var SQLITE_CONSTRAINT_TRIGGER: Int32 { return (SQLITE_CONSTRAINT | (7 << 8)) }
    public static var SQLITE_CONSTRAINT_UNIQUE: Int32 { return (SQLITE_CONSTRAINT | (8 << 8)) }
    public static var SQLITE_CONSTRAINT_VTAB: Int32 { return (SQLITE_CONSTRAINT | (9 << 8)) }
    public static var SQLITE_CONSTRAINT_ROWID: Int32 { return (SQLITE_CONSTRAINT | (10 << 8)) }
    public static var SQLITE_NOTICE_RECOVER_WAL: Int32 { return (SQLITE_NOTICE | (1 << 8)) }
    public static var SQLITE_NOTICE_RECOVER_ROLLBACK: Int32 { return (SQLITE_NOTICE | (2 << 8)) }
    public static var SQLITE_WARNING_AUTOINDEX: Int32 { return (SQLITE_WARNING | (1 << 8)) }
    public static var SQLITE_AUTH_USER: Int32 { return (SQLITE_AUTH | (1 << 8)) }
    public static var SQLITE_OK_LOAD_PERMANENTLY: Int32 { return (SQLITE_OK | (1 << 8)) }

    public static var SQLITE_TRANSIENT = unsafeBitCast(-1, to: SQLite3.sqlite3_destructor_type.self)
    public static var SQLITE_STATIC = unsafeBitCast(0, to: SQLite3.sqlite3_destructor_type.self)

    open func sqlite3_open(_ filename: UnsafePointer<Int8>!, _ ppDb: UnsafeMutablePointer<OpaquePointer?>!) -> Int32 {
        return SQLite3.sqlite3_open(filename, ppDb)
    }

    open func sqlite3_libversion_number() -> Int32 {
        return SQLite3.sqlite3_libversion_number()
    }

    open func sqlite3_libversion() -> UnsafePointer<Int8>! {
        return SQLite3.sqlite3_libversion()
    }

    open func sqlite3_sourceid() -> UnsafePointer<Int8>! {
        return SQLite3.sqlite3_sourceid()
    }

    open func sqlite3_close(_ db: OpaquePointer!) -> Int32 {
        return SQLite3.sqlite3_close(db)
    }

    open func sqlite3_prepare_v2(_ db: OpaquePointer!,
                                 _ zSql: UnsafePointer<Int8>!,
                                 _ nByte: Int32,
                                 _ ppStmt: UnsafeMutablePointer<OpaquePointer?>!,
                                 _ pzTail: UnsafeMutablePointer<UnsafePointer<Int8>?>!) -> Int32 {
        return SQLite3.sqlite3_prepare_v2(db, zSql, nByte, ppStmt, pzTail)
    }

    open func sqlite3_finalize(_ pStmt: OpaquePointer!) -> Int32 {
        return SQLite3.sqlite3_finalize(pStmt)
    }

    open func sqlite3_get_autocommit(_ db: OpaquePointer!) -> Int32 {
        return SQLite3.sqlite3_get_autocommit(db)
    }

    open func sqlite3_step(_ pStmt: OpaquePointer!) -> Int32 {
        return SQLite3.sqlite3_step(pStmt)
    }

    open func sqlite3_column_count(_ pStmt: OpaquePointer!) -> Int32 {
        return SQLite3.sqlite3_column_count(pStmt)
    }

    open func sqlite3_column_type(_ pStmt: OpaquePointer!, _ iCol: Int32) -> Int32 {
        return SQLite3.sqlite3_column_type(pStmt, iCol)
    }

    open func sqlite3_column_bytes(_ pStmt: OpaquePointer!, _ iCol: Int32) -> Int32 {
        return SQLite3.sqlite3_column_bytes(pStmt, iCol)
    }

    open func sqlite3_column_double(_ pStmt: OpaquePointer!, _ iCol: Int32) -> Double {
        return SQLite3.sqlite3_column_double(pStmt, iCol)
    }

    open func sqlite3_column_int64(_ pStmt: OpaquePointer!, _ iCol: Int32) -> sqlite3_int64 {
        return SQLite3.sqlite3_column_int64(pStmt, iCol)
    }

    open func sqlite3_column_text(_ pStmt: OpaquePointer!, _ iCol: Int32) -> UnsafePointer<UInt8>! {
        return SQLite3.sqlite3_column_text(pStmt, iCol)
    }

    open func sqlite3_column_blob(_ pStmt: OpaquePointer!, _ iCol: Int32) -> UnsafeRawPointer! {
        return SQLite3.sqlite3_column_blob(pStmt, iCol)
    }

    open func sqlite3_reset(_ pStmt: OpaquePointer!) -> Int32 {
        return SQLite3.sqlite3_reset(pStmt)
    }

    open func sqlite3_bind_double(_ pStmt: OpaquePointer!, _ index: Int32, _ zValue: Double) -> Int32 {
        return SQLite3.sqlite3_bind_double(pStmt, index, zValue)
    }

    open func sqlite3_bind_int64(_ pStmt: OpaquePointer!, _ index: Int32, _ zValue: sqlite3_int64) -> Int32 {
        return SQLite3.sqlite3_bind_int64(pStmt, index, zValue)
    }

    open func sqlite3_bind_null(_ pStmt: OpaquePointer!, _ index: Int32) -> Int32 {
        return SQLite3.sqlite3_bind_null(pStmt, index)
    }

    open func sqlite3_bind_text(_ pStmt: OpaquePointer!,
                                _ index: Int32,
                                _ zValue: UnsafePointer<Int8>!,
                                _ nByte: Int32,
                                _ destructor: (@convention(c) (UnsafeMutableRawPointer?) -> Swift.Void)!) -> Int32 {
        return SQLite3.sqlite3_bind_text(pStmt, index, zValue, nByte, destructor)
    }

    open func sqlite3_bind_blob(_ pStmt: OpaquePointer!,
                                _ index: Int32,
                                _ zValue: UnsafeRawPointer!,
                                _ nByte: Int32,
                                _ destructor: (@convention(c) (UnsafeMutableRawPointer?) -> Swift.Void)!) -> Int32 {
        return SQLite3.sqlite3_bind_blob(pStmt, index, zValue, nByte, destructor)
    }

    open func sqlite3_bind_parameter_index(_ pStmt: OpaquePointer!, _ zName: UnsafePointer<Int8>!) -> Int32 {
        return SQLite3.sqlite3_bind_parameter_index(pStmt, zName)
    }

    open func sqlite3_errmsg(_ db: OpaquePointer!) -> UnsafePointer<Int8>! {
        return SQLite3.sqlite3_errmsg(db)
    }

    open func sqlite3_errstr(_ code: Int32) -> UnsafePointer<Int8>! {
        return SQLite3.sqlite3_errstr(code)
    }

}
