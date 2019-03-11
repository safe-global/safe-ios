//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public class DataProtectionAwareCSQLite3: CSQLite3 {

    private let filesystemGuard: FileSystemGuard

    public init(filesystemGuard: FileSystemGuard) {
        self.filesystemGuard = filesystemGuard
        super.init()
    }

    public override func sqlite3_open(_ filename: UnsafePointer<Int8>!,
                                      _ ppDb: UnsafeMutablePointer<OpaquePointer?>!) -> ResultCode {
        let semaphore = DispatchSemaphore(value: 0)
        filesystemGuard.addUnlockSemaphore(semaphore)
        if Thread.isMainThread {
            while !filesystemGuard.hasAccess {
                Timer.wait(0.1)
            }
        } else {
            semaphore.wait()
        }
        return super.sqlite3_open(filename, ppDb)
    }

}
