//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Database

class CSQLite3ErrorTests: XCTestCase {

    // swiftlint:disable function_body_length
    func test_errorMessageNotNil() {
        assertErrorMessage(CSQLite3.SQLITE_OK)
        assertErrorMessage(CSQLite3.SQLITE_ERROR)
        assertErrorMessage(CSQLite3.SQLITE_INTERNAL)
        assertErrorMessage(CSQLite3.SQLITE_PERM)
        assertErrorMessage(CSQLite3.SQLITE_ABORT)
        assertErrorMessage(CSQLite3.SQLITE_BUSY)
        assertErrorMessage(CSQLite3.SQLITE_LOCKED)
        assertErrorMessage(CSQLite3.SQLITE_NOMEM)
        assertErrorMessage(CSQLite3.SQLITE_READONLY)
        assertErrorMessage(CSQLite3.SQLITE_INTERRUPT)
        assertErrorMessage(CSQLite3.SQLITE_IOERR)
        assertErrorMessage(CSQLite3.SQLITE_CORRUPT)
        assertErrorMessage(CSQLite3.SQLITE_NOTFOUND)
        assertErrorMessage(CSQLite3.SQLITE_FULL)
        assertErrorMessage(CSQLite3.SQLITE_CANTOPEN)
        assertErrorMessage(CSQLite3.SQLITE_PROTOCOL)
        assertErrorMessage(CSQLite3.SQLITE_EMPTY)
        assertErrorMessage(CSQLite3.SQLITE_SCHEMA)
        assertErrorMessage(CSQLite3.SQLITE_TOOBIG)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT)
        assertErrorMessage(CSQLite3.SQLITE_MISMATCH)
        assertErrorMessage(CSQLite3.SQLITE_MISUSE)
        assertErrorMessage(CSQLite3.SQLITE_NOLFS)
        assertErrorMessage(CSQLite3.SQLITE_AUTH)
        assertErrorMessage(CSQLite3.SQLITE_FORMAT)
        assertErrorMessage(CSQLite3.SQLITE_RANGE)
        assertErrorMessage(CSQLite3.SQLITE_NOTADB)
        assertErrorMessage(CSQLite3.SQLITE_NOTICE)
        assertErrorMessage(CSQLite3.SQLITE_WARNING)
        assertErrorMessage(CSQLite3.SQLITE_ROW)
        assertErrorMessage(CSQLite3.SQLITE_DONE)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_READ)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_SHORT_READ)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_WRITE)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_FSYNC)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_DIR_FSYNC)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_TRUNCATE)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_FSTAT)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_UNLOCK)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_RDLOCK)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_DELETE)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_BLOCKED)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_NOMEM)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_ACCESS)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_CHECKRESERVEDLOCK)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_LOCK)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_CLOSE)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_DIR_CLOSE)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_SHMOPEN)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_SHMSIZE)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_SHMLOCK)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_SHMMAP)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_SEEK)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_DELETE_NOENT)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_MMAP)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_GETTEMPPATH)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_CONVPATH)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_VNODE)
        assertErrorMessage(CSQLite3.SQLITE_IOERR_AUTH)
        assertErrorMessage(CSQLite3.SQLITE_LOCKED_SHAREDCACHE)
        assertErrorMessage(CSQLite3.SQLITE_BUSY_RECOVERY)
        assertErrorMessage(CSQLite3.SQLITE_BUSY_SNAPSHOT)
        assertErrorMessage(CSQLite3.SQLITE_CANTOPEN_NOTEMPDIR)
        assertErrorMessage(CSQLite3.SQLITE_CANTOPEN_ISDIR)
        assertErrorMessage(CSQLite3.SQLITE_CANTOPEN_FULLPATH)
        assertErrorMessage(CSQLite3.SQLITE_CANTOPEN_CONVPATH)
        assertErrorMessage(CSQLite3.SQLITE_CANTOPEN_DIRTYWAL)
        assertErrorMessage(CSQLite3.SQLITE_CORRUPT_VTAB)
        assertErrorMessage(CSQLite3.SQLITE_READONLY_RECOVERY)
        assertErrorMessage(CSQLite3.SQLITE_READONLY_CANTLOCK)
        assertErrorMessage(CSQLite3.SQLITE_READONLY_ROLLBACK)
        assertErrorMessage(CSQLite3.SQLITE_READONLY_DBMOVED)
        assertErrorMessage(CSQLite3.SQLITE_ABORT_ROLLBACK)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_CHECK)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_COMMITHOOK)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_FOREIGNKEY)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_FUNCTION)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_NOTNULL)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_PRIMARYKEY)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_TRIGGER)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_UNIQUE)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_VTAB)
        assertErrorMessage(CSQLite3.SQLITE_CONSTRAINT_ROWID)
        assertErrorMessage(CSQLite3.SQLITE_NOTICE_RECOVER_WAL)
        assertErrorMessage(CSQLite3.SQLITE_NOTICE_RECOVER_ROLLBACK)
        assertErrorMessage(CSQLite3.SQLITE_WARNING_AUTOINDEX)
        assertErrorMessage(CSQLite3.SQLITE_AUTH_USER)
        assertErrorMessage(CSQLite3.SQLITE_OK_LOAD_PERMANENTLY)
    }

}

extension CSQLite3ErrorTests {

    private func assertErrorMessage(_ code: Int32) {
        let msg = errorMessage(code)
        if msg == nil {
            XCTFail("No error message provided for code \(code)")
        } else {
            print(msg!)
        }
        XCTAssertNotNil(msg)
    }

    private func errorMessage(_ code: Int32) -> String? {
        guard let cString = CSQLite3().sqlite3_errstr(code) else { return nil }
        return String(cString: cString, encoding: .utf8)
    }

}
